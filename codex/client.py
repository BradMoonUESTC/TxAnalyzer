import json
import os
import subprocess
import sys
import threading
from dataclasses import dataclass
from typing import Any, List, Optional


class CodexError(RuntimeError):
    pass


@dataclass
class CodexResult:
    final_text: str
    agent_messages: List[str]
    token_count_info: Optional[Any]


def _check_codex_available() -> None:
    try:
        r = subprocess.run(["codex", "--version"], capture_output=True, text=True, timeout=10)
    except Exception as e:
        raise CodexError(f"无法执行 codex：{e}") from e
    if r.returncode != 0:
        raise CodexError(f"codex 不可用（退出码 {r.returncode}）：{(r.stderr or r.stdout).strip()}")


def _parse_codex_jsonl(stdout: str) -> CodexResult:
    agent_messages: List[str] = []
    token_count_info: Optional[Any] = None

    for ln in stdout.splitlines():
        if not ln.strip():
            continue
        try:
            obj = json.loads(ln)
        except json.JSONDecodeError:
            continue

        msg = obj.get("msg", {})
        msg_type = msg.get("type", "")
        if msg_type == "agent_message":
            text = msg.get("message", "")
            if text:
                agent_messages.append(text)
        elif msg_type == "token_count":
            token_count_info = msg.get("info")

    if not agent_messages:
        raise CodexError("codex 输出里没有找到 agent_message（可能是鉴权/配置/输出格式问题）")

    return CodexResult(
        final_text=agent_messages[-1],
        agent_messages=agent_messages,
        token_count_info=token_count_info,
    )


def ask_codex(
    *,
    project_path: str,
    question: str,
    model: str = "gpt-5",
    reasoning_effort: str = "high",
    auth_method: str = "apikey",
    sandbox: str = "read-only",
    ask_for_approval: Optional[str] = None,
    output_last_message_path: Optional[str] = None,
    timeout_sec: int = 1800,
    stream_output: bool = False,
    use_json_events: bool = False,
) -> CodexResult:
    """
    对本地项目目录进行只读提问（通过 codex CLI）。
    """
    project_path = os.path.abspath(os.path.expanduser(project_path))
    if not os.path.isdir(project_path):
        raise CodexError(f"项目目录不存在：{project_path}")

    _check_codex_available()

    # 提示：apikey 方式通常需要 OPENAI_API_KEY；但也可能你已通过 codex 本机配置完成鉴权
    if auth_method == "apikey" and not os.environ.get("OPENAI_API_KEY"):
        print(
            "[WARN] 未检测到环境变量 OPENAI_API_KEY。若 codex 尚未完成本机鉴权/配置，调用可能会失败。\n"
            "      你可以先在终端执行：export OPENAI_API_KEY='sk-...'\n",
            file=sys.stderr,
        )

    cmd: List[str] = [
        "codex",
        "exec",
        "--config",
        f'preferred_auth_method="{auth_method}"',
        "-m",
        model,
        "-s",
        sandbox,
        "--skip-git-repo-check",
        "--cd",
        project_path,
        question,
    ]

    # 控制审批模式（避免非交互脚本卡在 approval）
    # 注意：--ask-for-approval 是全局参数，必须放在 `exec` 子命令之前：
    # codex --ask-for-approval never exec ...
    # https://developers.openai.com/codex/cli/reference
    if ask_for_approval is not None:
        cmd[1:1] = ["--ask-for-approval", ask_for_approval]

    # 官方文档：Codex 默认输出为 formatted text；加 --json 才输出 JSONL events
    # https://developers.openai.com/codex/cli/reference
    if use_json_events:
        cmd.insert(-1, "--json")

    # 官方：--output-last-message, -o <path>（由 CLI 落盘最终回答，不依赖 agent 写文件）
    # https://developers.openai.com/codex/cli/reference
    if output_last_message_path:
        prompt_idx = len(cmd) - 1
        cmd[prompt_idx:prompt_idx] = ["--output-last-message", output_last_message_path]

    # 注入推理强度参数（借鉴你原来的 AgentCodex 逻辑）
    if model in {"gpt-5-codex", "gpt-5", "gpt-5-mini", "gpt-5-nano", "o3", "o3-mini", "o4-mini", "o1"}:
        # 不能用 insert(-2)：因为末尾是 [--cd, project_path, PROMPT]，-2 会落在 project_path 位置导致 --cd 断参
        # 这里把配置插在 "-m <model>" 后面，避免影响 --cd 和 PROMPT
        model_idx = cmd.index("-m")
        insert_at = model_idx + 2
        cmd[insert_at:insert_at] = ["--config", f'model_reasoning_effort="{reasoning_effort}"']

    if not stream_output:
        r = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=project_path,
            timeout=timeout_sec,
        )
        if r.returncode != 0:
            raise CodexError(f"codex 执行失败（退出码 {r.returncode}）：{(r.stderr or '').strip() or 'unknown error'}")
        if use_json_events:
            return _parse_codex_jsonl(r.stdout)
        # 非 JSON 模式：直接把 formatted text 作为 final_text 返回
        out = (r.stdout or "").strip()
        if not out:
            raise CodexError("codex 输出为空（可能是鉴权/配置/项目路径问题）")
        return CodexResult(final_text=out, agent_messages=[out], token_count_info=None)

    # streaming 模式：需要同时读取 stdout/stderr，避免 stderr pipe 填满导致卡住
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        cwd=project_path,
        bufsize=1,  # line-buffered
        universal_newlines=True,
    )

    stdout_chunks: List[str] = []
    stderr_chunks: List[str] = []
    agent_messages: List[str] = []
    token_count_info: Optional[Any] = None

    lock = threading.Lock()

    def stdout_worker() -> None:
        nonlocal token_count_info
        assert proc.stdout is not None
        for ln in proc.stdout:
            with lock:
                stdout_chunks.append(ln)

            if not use_json_events:
                # formatted text 模式：直接逐行打印即可（这才是真正的“stream 输出”）
                if ln:
                    print(ln, end="", flush=True)
                continue

            # JSON events 模式：解析 JSONL，遇到 agent_message 就打印
            s = ln.strip()
            if not s:
                continue
            try:
                obj = json.loads(s)
            except json.JSONDecodeError:
                continue

            msg = obj.get("msg", {})
            msg_type = msg.get("type", "")
            if msg_type == "agent_message":
                text = msg.get("message", "")
                if text:
                    with lock:
                        agent_messages.append(text)
                    print(text, flush=True)
            elif msg_type == "token_count":
                token_count_info = msg.get("info")

    def stderr_worker() -> None:
        assert proc.stderr is not None
        for ln in proc.stderr:
            with lock:
                stderr_chunks.append(ln)
            # codex 如果把进度写 stderr，你也能实时看到（便于判断是不是“卡住”）
            if ln.strip():
                print(f"[codex:stderr] {ln.rstrip()}", file=sys.stderr, flush=True)

    t_out = threading.Thread(target=stdout_worker, daemon=True)
    t_err = threading.Thread(target=stderr_worker, daemon=True)
    t_out.start()
    t_err.start()

    try:
        proc.wait(timeout=timeout_sec)
    except subprocess.TimeoutExpired:
        proc.kill()
        raise CodexError("codex 执行超时")

    # 等待读取线程收尾
    t_out.join(timeout=2)
    t_err.join(timeout=2)

    if proc.returncode != 0:
        with lock:
            stderr_text = "".join(stderr_chunks).strip()
        raise CodexError(f"codex 执行失败（退出码 {proc.returncode}）：{stderr_text or 'unknown error'}")

    with lock:
        if use_json_events:
            if not agent_messages:
                # fallback：万一 streaming 过程中没解析到，最后再整体 parse 一次
                return _parse_codex_jsonl("".join(stdout_chunks))
            return CodexResult(
                final_text=agent_messages[-1],
                agent_messages=agent_messages,
                token_count_info=token_count_info,
            )

        # formatted text：把全部 stdout 拼成 final_text（也方便你后续保存/处理）
        out = "".join(stdout_chunks).strip()
        if not out:
            raise CodexError("codex 输出为空（可能是鉴权/配置/项目路径问题）")
        return CodexResult(final_text=out, agent_messages=[out], token_count_info=None)


