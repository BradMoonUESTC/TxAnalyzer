## 目标与适用范围

这份方法论用于**攻击交易（exploit tx）**的系统化分析，覆盖 AMM/DEX、借贷/Vault、预言机、权限/签名、重入/回调、代理/实现错配、非标准 ERC20、tokenomics/通缩/奖励分发等常见攻击类别。

设计目标是**特别适合 LLM**：尽量避免“人肉读汇编”，改为**证据驱动 + 因果闭环 + 最小证伪**的流程，让 LLM 在海量 trace 中快速收敛到唯一 root cause。

---

## 总体原则（最重要的抽象层）

- **先找“谁改了账本”，再解释“别人看到了什么”**  
  链上系统可以类比数据库：最硬的因果链永远是  
  **写入（SSTORE/状态改变）→ 读取（SLOAD/view 返回值）→ 触发（协议逻辑）→ 盈利（资产回流）**。  
  先从“读到异常值”倒推很容易误判。

- **维护“竞争解释集”，用最小检查快速证伪**  
  看到一个异常现象（价格、储备、余额、份额等），不要立刻讲故事。至少保留 2–4 个互斥解释，并为每个解释写出“最短证据需求”，用成本最低的检查先砍掉错误分支。

- **证据强度分层：状态写入 > 可复算数值 > 事件 > 反编译/源码 > 直觉**  
  关键结论必须落在高等级证据上（尤其是“谁写了什么状态、写到哪里”）。

- **默认对抗：假设对方会骗你**  
  恶意 token/合约常见手段是“骗协议/骗分析者”：caller 依赖的 `balanceOf`、对 Pair/Router 特判转账、伪装事件、代理上下文混淆等。方法论必须能抵抗这种对抗性。

- **区分“造条件动作”与“变现动作”**  
  很多攻击的最后一跳只是普通 `swap/redeem/withdraw/liquidate`；真正 root cause 往往在更早的**准备/累计/flush/同步**链路。  
  若你只能解释“钱怎么出来”，却解释不了“异常状态是怎么在同一笔交易里被造出来的”，说明分析仍停在表层。

- **把“累计桶 / 延迟结算态”当作一等公民**  
  对 `pending fee`、`reward debt`、`pending burn`、`distributor credit`、`debt bucket`、`rebalance buffer` 这类状态，不要当“业务细节”略过。  
  它们常常是攻击者可控的**中间蓄水池**：先累积，再通过公开 `flush/claim/settle/sync` 入口一次性作用到 Pair/Vault/Oracle。

- **禁止“无证据的否定句”**  
  在攻击分析里，“没有发生 X / 未观察到 X”往往是误判源。  
  若你要写否定句，必须同时给出：  
  - 你用于排查的**明确搜索范围与模式**（例如“在 trace 中检索 `exchange(` / `swap` / `liquidate`”）  
  - 或者给出“为何可排除”的硬证据（例如某组件输入分量在 tx 内两次采样完全一致）。  
  否则只能写成“尚未在已检查窗口内定位到 X（并列出下一步最小排查动作）”。

- **穿透所有信任边界，不在中间层停下（极重要）**  
  一次攻击通常跨越多层信任边界（proof verification → message dispatcher → application handler → token logic）。**"应用层解释已能闭环"不是停止的理由**——你必须追问"攻击者是怎么到达这一层的？上一层的校验/验证代码是否正确？"  
  - 对攻击路径上的每一个校验/验证函数（`verifyProof`、`ecrecover`、`require(msg.sender==...)`、`authenticate`、`processProof`、`calculateRoot` 等），**必须打开其完整源码逐行审查**  
  - 即使某一层"看起来正确"，也必须检查其**边界条件**（零长度输入、index 越界、空 proof、除零、`leaf_index >= leafCount` 等）  
  - 如果你在某一层就停下了，问自己：**"如果只修复了这一层，攻击者是否还能通过更底层的 bug 伪造合法输入来绕过修复？"** 如果答案是"可能"或"不确定"，你还没找到真正的 root cause

> **强制规范（不可违反）**：见 `ATTACK_TX_ANALYSIS_SPEC.md`（含 Write-object-first Gate、置信度闸门、停止条件、强制句式）。

---

## 六阶段工作流（LLM 友好）

### 阶段 1：交易体检（Triage）

**输入**：交易 trace（含 call_type/from/to/input/output/error）、logs/events、token transfers、内部转账、（如有）状态前后快照。

**输出（结构化）**：
- **参与者清单**：EOA、攻击合约、受害合约、关键协议组件（pair/router/vault/oracle/proxy）。
- **资产流概览**：主要资产从哪来 → 经过哪些关键步骤 → 最终利润在哪。
- **阶段标签（强烈建议）**：把主干调用按 `finance/setup/accumulate/flush/extract/repay` 打标签，尤其关注**同一合约被重复调用**但函数职责不同的场景。
- **业务状态桶清单（强烈建议）**：列出本 tx 内出现的 `pending/reward/fee/burn/debt/distributor` 等累计态，并标注“谁增加它、谁清空它、谁读取它”。
- **第三方受影响面**：是否存在“对非攻击者地址的状态改变”（被清算/被换仓/被强制平仓/被转移抵押品）；若存在，先列出**受影响地址集合**与**作用方式**（例如 `liquidate(user)`、批量 `users_to_liquidate`、LLAMMA `exchange` 触发的仓位换仓）。
- **异常指标**：哪些数值/行为“不应发生”（例如储备突变、份额突增、价格瞬时拉爆、某函数异常频繁被调用、重入样式调用树等）。
- **利润来源归类（强烈建议）**：把利润按“来源机制”归类（AMM 套利 / 借贷放款套利 / 清算收益 / 手续费回流 / 赎回差价 / 代币税/重定向等），避免把“融资步骤（flashloan/borrow）”误当成“利润机制”。

> 该阶段只做“定位异常与主干路径”，不下结论。

---

### 阶段 2：画两张图（资金流图 + 控制流图）

- **资金流图（Money Flow Graph）**：节点=地址/合约，边=资产余额变化（转入/转出/增发/销毁/赎回/换币）。
- **控制流图（Call Graph）**：只保留与“异常指标 + 利润回流”相关的主干调用链，其余折叠为摘要。
- **阶段图（Phase Map，强烈建议）**：把主干路径再压成 3–6 个阶段，例如 `融资 → 累计 → flush/同步 → 变现 → 还款`。  
  这一步对“多机制链式利用 / 业务逻辑组合型 root cause”尤其关键。

**LLM 要做的事**：把“海量 trace”压缩成**可读的主干路径**。

> **强制补充（当存在第三方受影响面时）**：再画一张“受害者子图（Victim Subgraph）”，只回答：  
> **“价值从哪些第三方地址流向了攻击者？”**  
> 这能强制把分析主线对齐到“清算/强制换仓/头寸迁移”等真正的价值抽取点，而不是停留在攻击者自融资路径。

> **强制补充（当受害者子图存在时）**：再画一条“**受害者变差链（Degradation Chain）**”，只回答：  
> **“在被清算之前，是什么可控动作让这些第三方从健康 → 可被抽取？”**  
> 输出必须包含三段（允许并存）：  
> - **价格/预言机输入变化**（oracle component changed）  
> - **头寸被动迁移/自动换仓**（例如 banded AMM/LLAMMA 机制）  
> - **费用/利息/阈值边界**（close factor、penalty、rounding）  
> 目的：避免只看到“清算发生”但没解释“为什么会同时发生在很多人身上”。

> **通用约束（非常重要）**：Degradation Chain 的“推进动作”必须优先来自**外部 AMM/DEX swap**（Curve/Uniswap/Router 等），而不是只写“协议内部结算动作”（例如 liquidation 内部的 `withdraw`）。  
> 你可以把“内部 exchange/机制动作”写成第二段，但不能用它替代“外部价格推进/池子比例改变”的定位工作。

---

### 阶段 3：对每个异常建立“竞争解释集”

对每个异常现象（例如 reserve=502、share 变化异常、oracle 价格偏离），至少给出以下类型中的 2–4 个解释，并注明“最短证据需求”：

- **状态被改了（Write 型）**：存在关键状态写入（余额/储备/份额/价格/权限位）导致后续读到异常。
  - 最短证据：定位相关 `SSTORE`/状态更新点，确认写入对象与条件。
- **读出来被骗了（Read 型）**：view/返回值依赖 caller/条件（例如 `CALLER`/`EXTCODEHASH` 分支）返回“假值”。
  - 最短证据：同一输入在不同 caller 下返回不同输出；或在字节码/源码中看到明显分支条件依赖。
- **约束被绕过（Constraint 型）**：权限/签名/nonce/校验缺失或重放。
  - 最短证据：关键 require/check 缺失或可被绕过；签名域/nonce 处理错误。
- **时序被打穿（Order 型）**：重入/回调导致“先外部调用、后更新状态”，或跨合约顺序错误。
  - 最短证据：外部调用发生在状态更新前；存在回调入口且缺 guard。
- **外部依赖被操控（Dependency 型）**：oracle/TWAP/价格来源可被瞬时操控；或跨池套利。
  - 最短证据：价格来源是 spot/短窗 TWAP；攻击交易包含可操控的 swap/同步操作。
- **业务逻辑链式利用（Composition 型，通用且高频）**：多个单独看似“正常业务”的机制，在同一笔 tx 内可被串联，对**同一状态桶或同一结算对象**叠加生效。
  - 最短证据：至少列出 2 条可被攻击者到达的机制（如 `deposit/claim/sell/flush/distribute/sync`），并说明它们如何共同改变同一 `pending/reward/fee/burn/debt` 状态或同一 Pair/Vault/Oracle 读数。
- **参数选支 / 特殊接收者（Branch-select 型）**：同一函数会因 `from/to/receiver/path/msg.sender/tx.origin` 不同而走特殊逻辑。
  - 最短证据：定位分支条件或固定地址比较，并把它对齐到实际 tx 的输入参数（例如 `receiver=router`、`to=pair`、`path[i]=tokenX`）。
- **头寸机制被驱动（Mechanism 型，常被漏掉）**：某些协议的头寸会在价格/池子状态变化时发生**被动迁移/自动换仓/分段（bands）机制内的资产再平衡**（例如 LLAMMA bands），导致第三方健康度/抵押构成改变并触发清算。
  - 最短证据：在同一 tx（或紧邻步骤）出现“可显著推动价格/池子比例”的大额 swap/价格推进动作；并且协议内部出现与“分段/换仓/交换”相关的调用（如 `exchange`/band 相关读写），随后出现对第三方仓位的 `liquidate`/批量清算。
- **精度/舍入/单位错误（Math 型）**：decimal、share-to-asset 换算、rounding、上溢/下溢或自定义 safe math 错误。
  - 最短证据：公式可复算且产生攻击者优势；边界条件触发异常分支。
- **代理/实现错配（Proxy 型）**：proxy/implementation、delegatecall 上下文导致状态槽解释不同。
  - 最短证据：delegatecall 路径明确；同一 storage slot 在不同合约语义下被读写。

---
> **强制闸门（阶段 3.5）**：结算对象的“落账对象验证（Write-object-first Gate）”已移至 `ATTACK_TX_ANALYSIS_SPEC.md`。

### 阶段 3.6（新增，强烈建议执行）：Gate 取证操作手册（把 1a/1b 变成“可落地动作”）

> 这一节不改变 SPEC 的闸门定义，只提供“怎么拿到闸门证据”的工具化步骤，专门覆盖本次案例这类 **对抗性 token + AMM** 场景：`transfer(to=Pair)` 返回成功，但 `sync()/getReserves()` 读到 dust（例如 502）。

#### 3.6.1 先写“主矛盾”并锁定 3 个锚点

- **锚点 A（写入锚点）**：`transfer/transferFrom(to=结算对象)` 的那一跳（返回值/是否 revert 仅用于定位）。
- **锚点 B（读取锚点）**：结算对象在 `sync()/结算` 中读取的关键值（例如 `balanceOf(pair)=502` 或 `getReserves()`）。
- **锚点 C（利润锚点）**：最终利润落点（最后一次大额转出到攻击者/EOA）。

#### 3.6.2 竞争解释集（强制）与证伪顺序（固定：先 Write 后 Read）

- **假设 W（Write 型重定向/改账）**：扣款发生，但加款写给了“非结算对象”（固定地址/条件地址/另一个 key）。
- **假设 R（Read 型伪装）**：`balanceOf/getReserves` 存在 caller/条件依赖，返回假值。

证伪顺序永远是：

- **先做 1a/1b（写入对象验证）**：只回答“加款写给谁”。
- **再做 Read 伪装验证**：只有 Gate 结论为 A（确实入账）时，才把 Read 型当主要嫌疑。

#### 3.6.3 最短取证：把 `transfer` 拆成 1a/1b（对抗性 token 的“实锤模板”）

当 token 未开源/反编译不完整时，不要求你读懂全部逻辑；只要抓住下面三个“强信号”，就足以通过 Gate：

- **强信号 1：硬编码地址（PUSH20）**  
  在 `transfer/transferFrom` 的核心路径出现 `PUSH20 0x...`，且该地址进入“加款写入链路”，强烈暗示 **固定收款方/黑洞/税收/后门地址**。

- **强信号 2：1a 扣款链路（发送方余额）**  
  常见形态：`SHA3 → SLOAD → SUB → ... → SSTORE`  
  交付时必须写清：**扣的是哪个对象**（发送方/某个 key）、扣了多少、在什么条件下扣。

- **强信号 3：1b 加款链路（接收方余额）**  
  常见形态：`PUSH20 <addr> → SHA3 → SLOAD → ADD → SSTORE`  
  交付时必须写清：**加给了哪个对象**（若不是 `to=结算对象`，Gate 直接结论 B）。

> 如果同一路径里同时出现“1a 扣发送方 + 1b 加固定地址”，这就是 Write-object-first Gate 的最硬证据：**表面 `to=Pair`，实际落账对象被改写**。

#### 3.6.4 “只对 Pair 触发”的判定信号（用于解释触发条件，不用于替代写入证据）

当你怀疑 token 只在 AMM 场景触发特殊逻辑，可以寻找这些组合信号来解释“为何在对 Pair 时改写”：

- `EXTCODEHASH/EXTCODESIZE`（识别合约类型/代码哈希）
- 对 Router/Factory 的 `STATICCALL`（例如 `factory()` / `WETH()` / `getPair()`）
- caller/上下文检查（`CALLER/ORIGIN` 等）

这些信号用于补全“触发条件”，但 **不能替代 1a/1b 的 SSTORE 级证据**。

#### 3.6.5 交付物最小模板（推荐直接复制）

```text
Gate: Write-object-first
Status: PASSED
Conclusion: B (not credited to settlement object)

Evidence-1a (debit write object):
- function: transfer(...)
- SSTORE chain: SHA3 -> SLOAD -> SUB -> SSTORE
- object: sender balance mapping key = <...> (or sender address semantics)

Evidence-1b (credit write object):
- function: transfer(...)
- hardcoded recipient: 0x...
- SSTORE chain: PUSH20 0x... -> SHA3 -> SLOAD -> ADD -> SSTORE
- object: fixed address balance mapping key = <...>

Read anchor:
- sync()/getReserves reads dust = 502 (0x1f6)

Trigger:
- reserves updated -> swap pricing uses extreme reserve -> outputs WBNB

Profit:
- attacker/EOA receives <amount> WBNB
```

### 阶段 4：证据金字塔（优先级）

按以下优先级推进（越上越硬）：

- **一级（最硬）**：状态写入证据  
  - 关键槽位/映射被写入（`SSTORE`、协议内部状态更新）  
  - 写入值、写入对象、触发条件
- **二级**：可复算的数值证据  
  - AMM 定价/不变量、Vault share 公式、借贷健康度/清算阈值等能闭环复算
- **三级**：事件/日志证据  
  - Transfer/Swap/Sync/Mint/Burn 等（注意事件可被“叙事化”，不能单独定性）
- **四级**：源码/反编译证据  
  - 可读但可能缺块/错 CFG，需要回到更硬证据确认
- **五级**：模式匹配/直觉  
  - 只能用于提出假设，不用于最终定性

---

### 阶段 5：因果图闭环（Write → Read → Trigger → Profit）

最终 root cause 必须能用**同一条链**解释所有关键现象：

- **Write**：哪一次写入改变了哪个关键状态（余额/储备/份额/价格/权限位）
- **Read**：哪个组件（pair/vault/oracle）在关键时刻读到了什么（或被伪装的返回值）
- **Trigger**：协议基于该读数执行了什么（swap 定价、清算、赎回、借贷额度计算）
- **Profit**：资产如何回到攻击者并形成净利润

如果“某个关键异常”没有被闭环解释，说明**仍有漏掉的写入点或条件分支**。

> **新增闭环要求（当最终盈利动作只是普通 `swap/redeem/withdraw` 时）**：  
> 除了 `Write → Read → Trigger → Profit` 外，还必须补一条“**Preparation/Accumulation/Flush → Extraction**”阶段链：  
> **异常状态是如何在最终变现前被一步步造出来的？**  
> 若缺这条链，说明你只解释了“钱怎么出来”，还没解释“根因为什么成立”。

---
> **置信度闸门（阶段 5.5）**：已移至 `ATTACK_TX_ANALYSIS_SPEC.md`。

### 阶段 6：输出可复现结论（审计/修复友好）

建议强制用如下结构交付（便于复用与复盘）：

- **一句话 root cause**：必须可执行、不可歧义
- **触发条件**：前置状态/参数/调用顺序/权限关系
- **关键证据（3–6 条）**：trace 片段、关键返回值、关键写入点、关键公式闭环
- **攻击步骤最短复现（5–10 步）**
- **修复建议**：
  - 合约侧：校验/顺序/guard/公式修正/白名单
  - 协议侧：使用更稳健的 oracle/价格源、限制可疑 token 行为
  - 监控侧：异常指标告警（见后）
- **检测规则（监控指标）**：储备跳变、share 变化率、异常回调、caller 依赖的 view 等

---

## LLM 友好的“切片策略”（避免吞整条 trace）

- **按利润路径切片**：只保留与“资产最终回流”直接相关的调用子树
- **按异常点切片**：围绕异常发生点前后各 20–50 个调用窗口
- **按职责切片**：AMM 一组、Vault 一组、Oracle 一组、Token 一组、Proxy 一组

目标是让每轮输入都能回答一个明确问题：  
**“这个异常由哪一次写入导致？”** 或 **“这个返回值是否可被 caller/条件影响？”**

---

## LLM 友好的“字节码取证”套路（不要求人类读汇编）

当合约**未开源**、反编译**不完整/不可信**，或者你怀疑存在“对抗性 token/伪装读数”时，推荐使用这套**特征提取式**的字节码分析流程。目标不是让人类逐行读指令，而是让 LLM/脚本去做“模式识别 + 证据落点”。

### 1) 先定位函数入口（selector → entry PC）

常见 EVM dispatcher 会出现类似模式：`PUSH4 <selector> EQ PUSH2 <dest> JUMPI`。  
做法：

- **从 runtime bytecode 扫描** `PUSH4` + `EQ` + `JUMPI` 结构，得到 selector 到入口 `PC` 的映射
- 把关键函数的入口先钉死，例如：
  - ERC20：`transfer(0xa9059cbb)`、`balanceOf(0x70a08231)`、`transferFrom(0x23b872dd)`、`approve(0x095ea7b3)`
  - AMM：`swap`、`sync`、`getReserves`
  - Vault：`deposit/mint/withdraw/redeem`
  - Oracle：`latestAnswer/consult/getPrice`

**意义**：避免“在全局字节码里迷路”。入口确定后，只需要反汇编入口附近的**少量窗口**来做特征提取。

---

### 2) 把“读/写”拆开：优先找写入（SSTORE-first）

对 exploit 来说，最硬证据通常是“谁写了什么状态”。在字节码层你可以用以下模式快速定位关键写入：

- **映射写入（mapping）**常见形态：
  - `... MSTORE ... CODECOPY(<KEY>) ... SHA3 ... (SLOAD) ... (ADD/SUB) ... SSTORE`
  - 其中 `<KEY>` 常被编译器/反编译器处理成“从代码区 CODECOPY 一个 32 字节常量”（例如 mapping slot 的盐/种子）
- **总量/计数器写入**常见形态：
  - `SLOAD ... ADD/SUB ... SSTORE`（不一定有 `SHA3`）
- **权限位/开关写入**：
  - 低位 bitmask 的 `AND/OR/SHR/SHL` + `SSTORE`

> 你不需要理解每个栈变换，只要把“`SHA3` 前后的 KEY、`SSTORE` 的位置、以及附近出现的常量/地址”提取出来，就能形成可用证据。

---

### 3) 三类“强信号”快速识别对抗性逻辑

- **硬编码地址（PUSH20）**：  
  例如 `PUSH20 0x...` 出现在转账/铸造/赎回路径附近，强烈暗示“固定收款方/黑洞/团队/手续费地址/后门地址”。

- **事件 topic 常量（尤其 Transfer/Approval）**：  
  ERC20 的 `Transfer` topic 是 `ddf252ad...`，`Approval` 是 `8c5be1e5...`。  
  在某些字节码里，这些 topic 会以 32 字节常量形式出现（可能通过 `CODECOPY` 取出），再用于 `LOG3/LOG4`。  
  **用处**：你可以把“写余额”与“发事件”关联起来，确认哪条路径在“真实记账”。

- **caller/合约识别信号（对 DEX 特判常见）**：  
  `CALLER`、`ORIGIN`、`EXTCODEHASH`、`EXTCODESIZE`、`STATICCALL router/factory` 组合出现时，往往意味着“对交易对/路由器/特定合约走特殊分支”。

---

### 4) 把字节码证据和 trace 证据做闭环（最小闭环）

推荐固定做这 4 件事：

- **从 trace 里挑 3 个点**：
  - 触发点：攻击者调用的关键函数（例如 `transfer(to=pair)` / `deposit` / `borrow`）
  - 异常点：协议读到异常值的那次调用（例如 `pair.balanceOf(pair)=502` / `getReserves` 异常）
  - 盈利点：攻击者资产回流（swap 输出、withdraw、清算收益）
- **在字节码里找对应函数入口**（阶段 1）
- **在该函数附近找 SSTORE 链路**（阶段 2）
- **验证“对象”是否一致**：写入对象（哪一个地址/哪个 mapping key）要能解释 trace 的异常点

---

### 5) 交付物模板：字节码取证最小报告

建议 LLM/脚本最终输出如下字段，避免“只讲故事”：

- **selectors → entry PCs**：列出关键函数入口
- **写入点清单（SSTORE sites）**：每个写入点给出：
  - 位置（PC 或指令窗口）
  - 近邻特征：是否有 `SHA3`、是否出现 `PUSH20`、是否伴随 `LOG3/LOG4`
  - 推断对象：像是 balances mapping / totalSupply / flag
- **硬编码地址清单**（出现在哪条路径附近）
- **与 trace 的 1–2 条强对齐证据**（例如“该分支会把收款方改写到固定地址”）

---

## 常见攻击类别的模块化检查表（Checklist）

### 1) AMM / DEX
- **重点对象**：`swap/sync/getReserves/balanceOf(pair)`、flash swap 回调、fee-on-transfer
- **典型检查**：
  - **储备/余额一致性**：`reserve` 与 `balance` 是否一致；是否有 `sync()` 后异常跳变
  - **特殊 token 行为**：对 Pair 的 `transfer` 是否重定向/扣税；`balanceOf` 是否 caller 依赖
  - **TWAP 窗口**：是否过短、是否用 spot 当 oracle
  - **强制纠偏流程**：AMM + 对抗性 token 的三步“先落账对象、再读数伪装、再结算闭环”见 `ATTACK_TX_ANALYSIS_SPEC.md`。

#### 1.1) 大额 swap 推动型攻击（通用模块）
当你看到“批量清算/大量第三方同时变差”，必须假设存在“**价格推进动作**”（通常是一笔或几笔大额 swap），并执行最小检查：
- **定位候选 swap**：在 trace 中扫描/检索这些函数签名（任意命中即可）：  
  - `exchange(...)`（Curve/稳定池常见）  
  - `swap(...)`（UniswapV2/V3/自定义 AMM）  
  - `swapExactTokensForTokens(...)`（Router）  
- **按规模排序**：把候选 swap 按输入量（amountIn/dx）与输出量（amountOut/dy）排序，至少列出 Top-3，并标记其池子地址与 coin 索引（如 `i/j` 或 path）。
- **把“价格推进动作”对齐到“受害者变差链”**：swap 发生在“兑换率/预言机输入变化”之前还是之后？是否紧邻出现 banded AMM 的 `exchange`/`active_band`/user tick 读取？随后是否出现 `users_to_liquidate`/批量 `liquidate`？

- **强制 coin 解析（避免“i/j 不落地”）**：  
  只要 Top swaps 中出现 Curve 风格的 `exchange(i,j,...) / exchange_underlying(i,j,...)`，必须把 `i/j` 映射成“具体 token in/out”（至少给 token 地址），并说明证据来源（coins()/underlying_coins()/紧邻 Transfer 推断等）。  
  这条是通用要求：否则你无法可靠地产出“alUSD-sDOLA 池大额 swap”这类可核对结论。

> **关键提醒（避免误判）**：  
> - “清算结算动作”（`withdraw`/`transferFrom`）解释的是“价值如何被抽走”，不能替代“为什么会变得可抽走”。  
> - 如果你要把某个内部 `exchange` 写成 push_action，必须同时给出外部 swap 的 Top 列表，并解释为何外部 swap 不是主要推进动作（否则属于跳步）。

### 2) 借贷 / Vault / Share
- **重点对象**：`totalAssets/totalSupply`、share 铸造/赎回公式、rounding、donation 攻击
- **典型检查**：
  - **份额定价公式可复算闭环**：能否被捐赠/瞬时价格操控
  - **先后顺序**：先转账再铸 share？先外部调用再更新状态？
  - **ERC4626 必查（通用且高信号）**：如果抵押品/定价因子涉及 ERC4626 `convertToAssets/convertToShares` 或 share token：
    - 同 tx 内是否出现 `deposit/mint/withdraw/redeem`（影响 `totalSupply` 与份额销毁/铸造）
    - 是否存在“资产增加但 shares 不增”的路径（donation/第三方记账/转入 vault 但不铸 share）
    - 是否存在“shares 变化但资产不等价变化”的路径（赎回/提取/再质押/奖励释放节奏）
    - 若 oracle/健康度直接使用 `convertToAssets`，优先怀疑“share 定价可被原子性抬升/压低”，并分解其来源（`totalAssets` 变？`totalSupply` 变？两者都变？）

#### 2.1) ERC4626 “双旋钮”操纵（通用模块）
当你观察到 share 定价在同一 tx 内跳变，必须同时检查两类旋钮（缺一不可）：
- **Assets 旋钮（影响 totalAssets/资产口径）**：donation、第三方记账、奖励/利息即时入账、底层资产被直接转入但不铸 share。
- **Supply 旋钮（影响 totalSupply）**：`redeem/withdraw`（销毁 share）、`mint/deposit`（增发 share）、以及任何会“铸/销 share 但不按预期移动资产”的路径（含 stake/unstake/包装合约）。
交付要求：用一句话写清“本案主要靠哪个旋钮 + 是否叠加另一个旋钮”，并给出对齐到 trace 的锚点（调用点 + 跳变读数）。

> **通用加强（避免 supply 旋钮被“口头带过”）**：  
> 如果你提到 redeem/mint/deposit/withdraw 影响了 share 定价，必须同时给出 `totalSupply()` 的 before/after 读值锚点（同 tx 内），并列出所有 supply ops（redeem/mint/deposit/withdraw）的调用锚点与数量级。否则只允许把 supply 旋钮写成“待证假设”，不能写进 root cause 主链。

### 2.5) 清算 / 头寸迁移（Liquidation & Position Migration）
- **重点对象**：`liquidate`、批量清算器、`health`/`health_factor`、`users_to_liquidate`、LLAMMA/分段机制相关 `exchange`、oracle 输入构件（pool price、vault rate、聚合器）
- **典型检查**（按优先级）：
  - **清算是否是主利润来源**：只要交易里出现对多个第三方地址的清算/批量清算，默认把它当成主线，先画“受害者子图”
  - **为什么他们会变得可清算**：至少要回答下面三选一（可并存）：
    - 预言机输入变化导致估值变差（oracle jump / 组件变化）
    - 头寸抵押构成被动迁移（LLAMMA bands 导致从一种抵押换到另一种）
    - 借款/利息/费用使健康度跨线（close factor/fee/penalty）
  - **把价格推进动作与头寸变化对齐**：大额 swap/价格推进 →（bands/机制内换仓）→ 健康度跌破 → 清算发生 → 价值回流攻击者

#### 2.6) Banded AMM/LLAMMA 头寸迁移速查（通用模块）
当协议组件里出现“banded AMM/LLAMMA/分段做市”时，必须回答三问（否则不得收敛）：
1) **推进动作是什么？**（哪一次 swap/exchange 推进了价格/池子比例）  
2) **迁移发生在哪里？**（哪一次 `exchange`/band 相关调用导致头寸 x/y 构成变化；至少给出 1 个调用锚点）  
3) **迁移如何影响健康度？**（抵押构成偏向/估值输入变化，使得 health 跨线）  
输出无需完全复算，但必须把三问串成一条时间顺序明确的链，且链上每一问至少对应一个 trace 锚点。

> **通用纠偏**：如果你声称“bands 机制下持续换仓/头寸迁移导致用户变差”，你的锚点必须来自“清算前的机制动作/读写”（例如 `exchange`/tick/band 状态变化/用户 share 回调读取），而不是只引用“清算发生后的 withdraw”。

### 3) Oracle / 价格
- **重点对象**：spot vs TWAP vs Chainlink、staleness、更新权限、心跳
- **典型检查**：
  - **价格是否可被单笔交易拉动**
  - **数据是否过期/可回滚**

### 4) 权限 / 签名 / Permit
- **重点对象**：owner/admin、upgrade、nonce、domain separator、重放
- **典型检查**：
  - **缺失校验 / 错误 nonce 管理**
  - **delegatecall 上下文导致的权限绕过**

### 5) 重入 / 回调 / Hook
- **重点对象**：外部调用点、fallback、ERC777/回调、跨合约顺序
- **典型检查**：
  - **是否“先外部调用，后状态更新”**
  - **是否缺 ReentrancyGuard / 重入锁**

### 6) 非标准 ERC20 / Proxy（对抗性 token）
- **重点对象**：`transfer` 是否改写收款方、`balanceOf` 是否 caller 依赖、对 Pair/Router 特判
- **典型检查**：
  - **对 Pair 的转账是否被重定向到固定地址/黑洞/团队**
  - **同一 `balanceOf(pair)` 在不同 caller 下是否不同**
  - **是否依赖 `CALLER/EXTCODEHASH` 或外部探测（router/factory）**

### 7) Tokenomics / 通缩 / 奖励分发（业务逻辑组合）
- **重点对象**：`pending/reward/fee/burn/debt/distributor` 这类累计态，`claim/flush/settle/distribute/sync` 这类公开维护入口，以及 `from/to/receiver/path` 触发的特殊分支
- **典型检查**：
  - **同一状态桶是否被多条机制共同读写**：例如 `deposit` 增、`sell` 增、`claim/flush` 清、`sync` 落地
  - **是否存在“单独合理、组合危险”的设计**：多条机制都作用到同一 Pair/Vault/Oracle 读数或同一结算对象
  - **是否可单 tx 原子串联**：缺 access control、cooldown、epoch/rate limit，或公开维护函数可被任意人立即触发
  - **是否由特殊接收者/路径参数选中分支**：例如 `to=router/pair/dead/distributor`
  - **遇到此类场景时，强烈建议执行模块 H（多机制业务链与累计桶 flush）**

---

## 案例模板：当你“先猜错了”，如何快速修正（特别适合 LLM）

这一节专门总结“你给出答案之后，我的分析过程”应该如何抽象成可复用套路。核心思想是：**不和叙事纠缠，立刻用最小证据把分歧点钉死**。

### 场景：同一 `balanceOf(pair)` 在不同 caller 下不一致

这类现象常见于两类互斥根因（必须并行保留）：

- **假设 A：Read 型伪装**  
  `balanceOf` 对不同 caller/条件返回不同值（例如对 Pair 合约返回 502，对外部返回大数）
- **假设 B：Write 型改账/重定向**  
  `transfer(to=pair)` 事实上没有把钱记到 Pair，而是重定向到固定地址/扣税/写到别的 key，导致 Pair 的真实余额很小（例如仅剩 dust=502）

### 最小证伪顺序（推荐）

- **第一步（强制闸门）**：验证 `transfer(to=pair)` 的“落账对象”（Write-object-first）  
  - 只回答一个问题：**“加余额写给谁？”**  
  - 若发现“扣发送方 + 加固定地址/非 to”的写入对象不一致，直接定性为 **Write 型重定向/改账**（这是 root cause 级证据）。

- **第二步（再做）**：验证 `balanceOf` 是否 caller 依赖  
  - 在 `balanceOf` 入口窗口里找 `CALLER/EXTCODEHASH` 分支信号  
  - 用 trace 复验：同一输入不同 caller 是否稳定复现差异

### 为什么这个顺序更稳？

因为它把问题从“读到什么（可能被伪装）”切换到“写到了哪里（最硬）”。  
对抗性 token 里，“读”更容易作恶，“写”更难隐藏（最终一定要落在某些 `SSTORE` 上）。

### 纠偏清单：LLM 最常见的跑偏点（把复盘写成规则）

下面是从真实分析复盘提炼出的“强制纠偏规则”。它们的作用是：当你看到一些很“像攻击”的现象（例如关键读数忽大忽小、同一资产流在不同位置对不上），不要被叙事带跑，优先把分歧点用最小证据钉死。

- **先写一句“主矛盾”**（把海量 trace 压缩成一个要解释的冲突）  
  典型高信号格式（用占位符表达，避免绑定具体协议/函数名）：
  - `某个“写入/转移/更新”动作显示成功` **但** `紧接着被用作关键依据的“读取/结算/更新”动作读到的值没有相应变化`  
  - `事件/回执显示 A→B 转移完成` **但** `协议后续计算依赖的状态读数仍像“没收到/只收到 dust/收到异常少”`  
  这句主矛盾会把问题强制落到一个最硬的问题上：**写入到底写到了哪里？谁的账本被改了？**

- **强制维护“竞争解释集”，禁止单点定性**  
  对抗性合约/资产场景里，最常见的两条互斥解释必须并行保留，直到被证伪：
  - **Write 型**：写入对象被改写（重定向、写到别的 key/槽位/账户、条件分支导致“表面成功但未对目标入账”）
  - **Read 型**：读数被伪装（caller/条件依赖、对不同查询者返回不同值、对同一输入在不同时点返回不同值）

- **证伪顺序固定：先写后读（SSTORE-first）**  
  即使你暂时不做指令级分析，也要按这个顺序组织检查与叙事：
  - 先验证 Write 型：关键写入是否真的改变了“应当被改变的那个对象”（余额/储备/份额/权限位/计数器等）？若紧邻的关键读取仍像“没变化”，优先怀疑“写错对象/写到别处”
  - 再验证 Read 型：关键读取是否存在 caller/条件依赖？（它解释“为什么读数会变”，但通常不是解释“为什么写入与读取对不上”的首要原因）

- **把“现象证据”降级，不要让它主导 root cause**  
  例如“后面又出现一次很大的关键读数”只能说明行为异常，**不等价于**“root cause 就是 Read 型伪装”。  
  在对抗场景里，最稳的锚点永远是：**与协议关键状态更新/结算直接相关的那次读数**，以及它前面紧邻的写入动作是否自洽。

- **输出必须标注置信度与最小证伪动作**  
  在没有拿到落账对象（写入点/条件分支）的硬证据前，避免把某一条假设写成确定结论。推荐固定输出：
  - `hypotheses`: 至少两条互斥解释（Write/Read）
  - `minimal_check`: 每条解释的最短证伪动作（优先低成本、优先写入相关）
  - `confidence`: low/medium/high（并说明“提升到 high 还缺什么证据”）

> **强制句式**：为避免跳步，已移至 `ATTACK_TX_ANALYSIS_SPEC.md`。

---

## 更完整的攻击类型覆盖（建议逐步补齐到你的项目里）

如果你希望这份方法论文档成为“通用武器库”，建议后续继续补充以下类别的 checklist（这里先给提纲）：

- **跨链/桥（Bridge）**：消息验证、轻客户端/多签阈值、重放、payload 解析、链 ID/域分离
- **治理/权限升级（Governance/Upgrade）**：timelock 绕过、提案执行顺序、upgradeTo/initialize 重入、storage slot 冲突
- **清算/借贷边界（Liquidation Edge Cases）**：价格源 staleness、close factor、rounding、坏账吸收机制、批量清算器误用/可被引导、健康度计算的 oracle 组件可被原子性操纵（含 ERC4626 redemption rate）
- **只读重入（Read-only Reentrancy）**：view 函数读取依赖外部可变状态，导致同一 tx 内读数被操控
- **MEV 夹击/三明治（Sandwich）**：并非合约漏洞但造成资产损失；识别“前置/后置交易”与价格冲击

## 输出模板（建议直接复制使用）

### 1) 一句话 root cause

- **Root cause**：\<一句话，包含“哪个合约/函数/条件 → 写入了什么错误状态或伪装了什么读数 → 导致哪个协议组件误判”\>

### 2) 触发条件

- **前置状态**：\<资金/授权/池子状态/价格窗口等\>  
- **关键参数**：\<amount、path、to、deadline、mode 等\>  
- **调用顺序**：\<A→B→C，特别强调回调与重入入口\>

### 3) 关键证据（3–6 条）

- **证据 1（写入）**：\<谁在何处写入了哪个状态，写入值/对象\>  
- **证据 2（读取）**：\<哪个组件读到了什么异常值\>  
- **证据 3（触发）**：\<协议如何基于该读数执行关键动作\>  
- **证据 4（利润）**：\<资产如何回到攻击者\>
> 对抗性 token/AMM 场景的“写入证据 1a/1b 拆分”属于强制规范，详见 `ATTACK_TX_ANALYSIS_SPEC.md`。

> **补充（通用）**：如果你在正文里写了“价格从 A 变到 B”（例如 `price_w`/`price_oracle`/share price），必须在证据里给出 **before/after 两次读取锚点与原始值**；否则不要写具体数值变化。

### 4) 最短复现步骤（5–10 步）

- **Step 1**：\<准备/借贷/闪电贷\>  
- **Step 2**：\<操控状态或伪装读数\>  
- **Step 3**：\<触发协议误判\>  
- **Step 4**：\<套利/抽干\>  
- **Step 5**：\<还款/结算/利润落袋\>

### 5) 修复建议

- **合约侧**：\<校验/顺序/guard/白名单/公式修正\>  
- **协议侧**：\<更稳健 oracle、限制可疑 token、限制极端参数\>  
- **监控侧**：\<告警规则\>

---

## 给 LLM 的“每轮提示词骨架”（可按需裁剪）

你可以把每轮任务限制成“回答一个问题”，例如：

- **问题 A（先写后读）**：找出导致异常的最可能状态写入点，并列出 2–3 个竞争解释与最小证伪检查。
- **问题 B（对抗性读数）**：判断某个 view/返回值是否存在 caller 依赖或条件伪装，并给出可复现证据。
- **问题 C（闭环）**：把 Write→Read→Trigger→Profit 串成一条唯一因果链，并指出每一环的证据来源。

建议 LLM 每轮固定输出字段（便于收敛）：

```json
{
  \"actors\": [],
  \"assets\": [],
  \"anomalies\": [],
  \"hypotheses\": [
    {\"name\": \"...\", \"type\": \"Write|Read|Constraint|Order|Dependency|Math|Proxy\", \"minimal_check\": \"...\"}
  ],
  \"evidence\": [],
  \"next_actions\": [],
  \"confidence\": \"low|medium|high\"
}
```

---

## 何时可以停止（收敛停止条件）

满足以下条件即可认为 root cause 已“方法论闭环”：

- **至少一个关键写入点被定位并解释**（谁写、写哪、写什么、何条件）
- **所有关键异常现象都能用同一条因果链解释**（无“残差”）
- **利润路径可复算闭环**（资金流与关键公式一致）
- **结论可复现**（按最短步骤能重新描述攻击）

