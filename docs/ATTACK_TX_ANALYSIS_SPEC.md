## 攻击交易分析强制规范（SPEC）

> 这份文档是“不可违反”的分析规范，用来约束分析过程不跑偏。  
> 主方法论文档提供流程与工具箱；**本 SPEC 提供闸门、证据门槛与停止条件**。  
> 若与方法论文档存在冲突，以本 SPEC 为准。

---

## 1) 证据等级（必须遵守）

结论证据强度从高到低：

- **状态写入证据（Write/SSTORE 级）**：谁在何处写了什么、写给谁/写到哪个 key/槽位、在什么条件下写入。
- **可复算数值证据**：不变量/份额公式/清算阈值等能闭环复算的数学关系。
- **事件/日志证据**：只能用于定位与交叉验证，不能单独定性 root cause。
- **源码/反编译证据**：用于解释机制，但最终要回到更硬证据确认。
- **模式匹配/直觉**：只能用于提出假设，不能用于最终定性。

---

## 2) Write-object-first Gate（强制闸门）

### 2.1 何时必须触发闸门

只要异常涉及“结算对象”的关键读数或关键结算，就必须触发本闸门（任一命中即可）：

- Pair/Vault/借贷头寸/Oracle 等出现 **极端结算读数**（例如 reserve/份额价格/健康度/价格突然变成很小常数或突变）。
- 结算后出现 **抽干/输出接近 reserve/totalAssets** 等现象。
- trace 显示 `transfer(to=结算对象)` 返回成功，但紧接着结算读数仍像“没收到/只收到 dust”。

### 2.2 闸门要回答的唯一问题

> 这笔“应当入账到结算对象”的转移，最终到底记到谁的账本上？

### 2.3 闸门允许的结论（只能二选一）

- **结论 A：确实入账到结算对象**  
  - 最短证据需求：能证明“加余额/加资产/加份额”的写入对象就是 `to=结算对象`（或其语义等价 key/槽位）。
- **结论 B：没有入账到结算对象（被改写/重定向/写到别处）**  
  - 最短证据需求：能证明“扣款发生”与“加款发生”的写入对象不一致（例如加到固定地址/另一个 key/条件分支）。

### 2.4 禁止事项（闸门未通过时）

- 禁止把 root cause 定性为 **Read 型伪装**。
- 禁止用 **事件/回执/`balanceOf`** 直接替代“写入对象”证据通过闸门。

---

## 2.5 Victim-first Gate（清算/第三方价值抽取闸门，强制）

### 2.5.1 何时必须触发闸门

只要交易内出现任一信号，就必须触发本闸门（任一命中即可）：

- 出现对**非攻击者地址**的清算/强平相关调用（函数名可未知，但可通过语义/事件/参数识别：例如 `liquidate(user)`、`liquidate_extended`、批量清算器、`users_to_liquidate` 返回多个地址）。
- 同一 tx 内出现**大量第三方头寸状态变更**（例如批量遍历用户、对多个 user 调用同一“结算/清算/交换”路径）。

### 2.5.2 闸门要回答的唯一问题

> **价值是从哪些第三方地址被抽走的？它是通过什么协议动作（清算/被动换仓/罚金）流向攻击者的？**

### 2.5.3 闸门的最小交付物（LLM 友好）

必须输出以下字段（允许“部分未知”，但不能空缺）：

- `victims`: 至少列出 3 个（或全部）受害地址样例
- `extraction_action`: “清算/强制换仓/罚金/扣押抵押品/其他”
- `value_path`: 受害者资产（抵押或头寸价值） → 中间合约（controller/amm/liquidator） → 攻击者 的最短路径描述

### 2.5.4 禁止事项（闸门未通过时）

- 禁止把 root cause 的 Trigger/Profit 写成“攻击者借款/放款成功”而不解释第三方为何变得可被抽取。
- 禁止在存在第三方价值抽取证据时，把“融资步骤（flashloan/borrow/mint）”叙事化为主利润机制。

---

## 3) 竞争解释集与证伪顺序（强制顺序）

任何“异常现象”至少保留 2 条互斥解释，并按以下顺序证伪：

- **先 Write（写到哪里）**：先验证写入对象是否正确（是否写给了应当被写的对象）。
- **再 Read（读到什么）**：再验证读数是否存在 caller/条件依赖、是否可被伪装。

> 若你发现“读数忽大忽小”，第一反应仍应是：**写入对象是否被改写/重定向**。

---

## 4) root cause 置信度闸门（强制门槛）

- **high**：必须包含至少 1 条“写入对象”级别证据（谁写、写给谁/写到哪个 key/槽位、写入值/条件），并能解释关键异常。
- **medium**：已定位关键写入点，但写入对象/条件仍不完全确定；或只能在有限假设下闭环。
- **low**：没有通过 Write-object-first Gate 的情况下，任何 Read 型解释只能是 low，并必须写清每条假设的“最短证伪动作”。

> **附加门槛（当 root cause 属于业务逻辑链式利用 / multi-step composition 时）**：  
> 要提升到 `high`，除写入证据外，还必须明确：
> - 至少 **2 条** 攻击者可到达的机制
> - 至少 **1 个** 共享状态桶或共享结算对象
> - 明确区分 `flush_or_settlement_action` 与 `extraction_action`

---

## 5) 强制输出约束（防止叙事化）

### 5.1 必须写“主矛盾”

用一句话把海量 trace 压缩成一个冲突，模板：

- `某个写入/转移动作显示成功` **但** `紧接着用于结算的读取/更新读数没有相应变化`

### 5.2 必须写 Write→Read→Trigger→Profit 闭环

root cause 必须能用同一条链解释：

- **Write**：写入点 + 写入对象 + 条件
- **Read**：关键结算读取到了什么
- **Trigger**：协议基于该读数做了什么结算
- **Profit**：资产如何回流形成净利润

### 5.2.1 Trigger/Profit 的主线选择规则（强制）

当交易内同时出现“融资步骤”（flashloan/borrow/mint）与“价值抽取步骤”（清算/扣押抵押/强制换仓导致第三方损失）时：

- **Trigger** 必须优先选择“直接导致第三方损失并把价值转移给攻击者”的动作（通常是清算/扣押/结算），而不是融资动作。
- 若你坚持把 Trigger 写成借贷放款/自借自还，必须在证据里明确证明：**不存在第三方受害者价值被抽取**，或抽取不是利润主要来源。

### 5.2.2 否定句约束（强制，防止“没看到就当不存在”）

如果你要写“未观察到/没有发生/不存在”这类否定句，必须同时输出：
- `negative_claim`: 你要否定的动作/现象（例如“没有 exchange”）
- `search_evidence`: 你检索过的模式与范围（例如“扫描 trace 中 decoded_input 的 `exchange(` / `swap`”或列出你检查过的调用窗口）

否则该否定句视为违反 SPEC（叙事化/跳步）。

### 5.3 建议把“写入证据”拆成 1a/1b（对抗性 token/AMM 场景）

- **证据 1a（扣款写入对象）**：发送方余额/关键状态如何被扣减（写给谁/哪个 key）
- **证据 1b（加款写入对象）**：接收方余额/关键状态如何被增加（写给谁/哪个 key）

若 1a 与 1b 的对象不一致，通常直接构成 root cause。

### 5.3.1 准备链 vs 变现链（当同一合约多次命中或存在累计桶/维护函数时强制）

当同一合约/系统在同一 tx 内被多次调用，且这些调用共同改变同一个状态桶或结算对象时，必须额外输出：

- `phase_map`: 至少从 `finance/setup/accumulate/flush/extract/repay` 中标出命中的阶段
- `shared_state_bucket`: 例如 `pending fee/reward/burn/debt/distributor credit`
- `shared_settlement_object`: 例如 Pair/Vault/Router/Distributor/Dead address/Oracle input
- `setup_or_accumulation_actions`: 哪些动作在为后续异常状态“蓄水”
- `flush_or_settlement_action`: 哪个动作把累计态真正落到账本/储备/价格输入/黑洞地址
- `extraction_action`: 哪个动作把异常状态变成利润（swap/redeem/withdraw/liquidate）
- `why_composable_in_one_tx`: 用 1-2 句解释“为什么攻击者可以原子化串联这些步骤”

### 5.3.2 特殊接收者 / 路径分支证据（当叙事涉及 `to/receiver/path/...` 选支时强制）

如果你的结论中出现以下表达，必须补证：
- “把 `receiver` 设成某地址就触发特殊逻辑”
- “对 `router/pair/dead/distributor` 走了特殊分支”
- “某条 path / 某个目标地址会命中不同转账/销毁/奖励逻辑”

必须输出：
- `branch_condition`: 触发分支的条件（例如 `to == router`、`receiver == router`、`path[i] == tokenX`）
- `actual_input_value`: 本次 tx 里实际传入的值
- `branch_effect`: 该分支具体改变了什么对象/状态（余额、储备、累计桶、黑洞转移、分发对象等）

### 5.3.3 禁止事项（上述场景未补全时）

- 禁止只把最后一跳 `swap/redeem/withdraw/liquidate` 写成 root cause，而不解释异常状态是如何被前序步骤造出来的。
- 禁止把会改变 `shared_state_bucket` 或 `shared_settlement_object` 的步骤统一降级成“只是准备动作”。
- 禁止在缺少 `branch_condition + actual_input_value + branch_effect` 时，把“特殊接收者/路径分支”写成确定性结论。

---

## 5.4 Oracle/健康度输入分解（当涉及清算/健康度时强制）

只要攻击路径涉及健康度/清算判定，就必须输出：

- `oracle_used_by`: 哪个合约在判定健康度/清算时读取了哪个 oracle/价格函数
- `oracle_components`: 该价格由哪些可控组件组成（例如 pool price、vault redemption rate、聚合器、折扣因子）
- `which_component_changed`: 在 tx 内到底是哪一项发生变化（必须能用“返回值对齐”锁定）

> 目的：避免“看到价格跳变就讲故事”，而是把跳变归因到可控输入（swap? ERC4626 rate? donation? redeem?）。

---

## 5.5 ERC4626/Share token 强制检查（当抵押品/预言机涉及 share 时）

当任一条件命中时必须执行本检查：

- 抵押品或 oracle 输入使用 `convertToAssets/convertToShares`、share 价格、`totalAssets/totalSupply`
- 或观察到 share 定价在同 tx 内突变

必须至少回答三问（通用且可执行）：

1) **是 `totalAssets` 变了，还是 `totalSupply` 变了，还是两者都变了？**  
2) **变化的写入入口是什么？**（donation/第三方记账/`deposit|mint|withdraw|redeem`/stake 等）  
3) **该变化如何进入 oracle/健康度判定？**（哪一次读取用了它）

并且：
- 如果你声称“supply 旋钮（redeem/mint/deposit/withdraw）”参与了操纵，必须执行模块 F（Supply 旋钮证据化），给出 `totalSupply_before_after` 与 `supply_ops`；否则不得把 supply 旋钮写成确定性原因链的一环。

---

## 5.6 批量清算原因闭环（当触发 Victim-first Gate 时强制）

当出现批量清算/大量第三方同时变差时，必须额外输出一个“受害者变差链（Degradation Chain）”，且必须包含以下字段：

- `push_action`: 至少一个可控推进动作（通常是大额 swap/exchange），给出 trace 锚点
- `migration_or_mechanism`: 若协议存在 banded AMM/LLAMMA/被动换仓机制，必须给出至少一个机制触发锚点（例如内部 `exchange`/band 相关调用）
- `oracle_component_changed`: 说明 oracle/健康度输入里到底哪一项发生变化（pool price? ERC4626 rate? 其他），并给出对齐证据
- `why_many_victims`: 用 1-2 句解释为何会同时影响很多人（例如同一条 oracle 输入/同一套 bands 再平衡逻辑）

> 如果无法给出 `push_action` 与 `migration_or_mechanism` 的任何锚点，则不得把“批量清算”写成确定性主线结论（最多 medium，且必须列出最短补证动作）。

### 5.6.1 push_action 的外部 swap 强制要求（高度通用）

当你输出 `push_action` 时，必须同时满足：
- **必须包含至少 1 个外部 AMM/DEX 的 swap/exchange 锚点**（Curve/Uniswap/Router 等），不能只写“协议内部 exchange”或“清算结算 withdraw”。
- 必须输出 `top_swaps`：列出本 tx 中按输入量排序的 Top-3 swap（可用 `decoded_input` 的 amount 参数或紧邻的 ERC20 转账金额作为 proxy），并给出每条的 trace 锚点与池子/路由器地址。

并且对 `top_swaps` 里的每一条 swap，必须额外输出：
- `in_token` / `out_token`（至少 token 地址；如能解析符号可附加）
- 若是 Curve i/j 形式，必须执行模块 E（池子 coin 解析），把 `i/j` 映射到具体 token（否则不允许写“alUSD-sDOLA”这类 token 对结论）

> 目的：避免把内部结算动作误当“价格推进动作”，从而漏掉你要的“外部池子大额 swap 改变比例/价格”这类真实驱动因素。

### 5.6.2 mechanism_action 的时间顺序要求（高度通用）

若你声称存在“机制迁移/被动换仓/bands 造成用户变差”，必须：
- 显式标注 `mechanism_action_happens_before_liquidation=true/false`
- 如果为 true：锚点必须来自 **`users_to_liquidate()` 之前** 的机制调用/状态读写（例如 `exchange`/band/tick/user share 回调/价格推进后的内部再平衡）。
- 如果为 false：必须明确承认它是“清算结算动作”，不能用它作为“用户变差原因”的主证据。

并且：若你声称存在“bands/机制导致头寸被动迁移/换仓”，必须执行模块 G（清算前迁移证据化），给出：
- `pre_liq_mechanism_calls`（清算前锚点，且不允许是 withdraw 结算）
- `victim_specific_evidence`（至少 1 个 victim 在清算前被机制调用直接引用）

否则不得把“被动迁移/换仓导致变差”写成确定性结论。

---

## 5.7 Oracle 输出值前后对齐（当叙事涉及“价格从 A 变到 B”时强制）

如果你的结论/叙事中出现类似“价格从 \(A\) 上升到 \(B\)”（例如 `price_w`、`price_oracle`、share price、健康度输入），则必须输出：
- `price_metric`: 你引用的具体函数/指标名（例如 `oracle.price_w()`）
- `before_anchor` / `after_anchor`: 两次读取的 trace 锚点（必须在同一 tx 内，且能定位到读值）
- `before_value` / `after_value`: 读到的原始数值（最好保留 1e18 精度的整数或 18 位小数）

否则不得使用“从 A 到 B”的数值叙事（只能写“发生显著跳变”，并给出最短补证动作）。

## 6) 强制句式（防止 LLM 跳步）

当你看到 `transfer(to=结算对象)` 显示成功 + `sync()/结算` 读到极小余额/极端值时，必须先写：

- `闸门状态：未通过/已通过；结论：A 或 B`
- `允许的下一步：`  
  - 未通过：只允许继续做“落账对象验证”，不允许把 root cause 写成 Read 型。  
  - 结论 B：直接进入“结算写入 → 触发 → 利润”闭环。  
  - 结论 A：才允许重点调查 Read/Order/Math/Proxy 等分支。

---

## 7) 停止条件（不满足就不能收敛，不满足就不能停）

满足以下条件才允许给出“最终 root cause（medium/high）”并结束：

- 至少一个关键写入点被定位并解释，且包含**写入对象**（写给谁/写到哪里）
- 所有关键异常现象能被同一条因果链解释（无“残差”）
- 利润路径可复算闭环（资金流与关键公式一致）
- **信任边界穿透（强制）**：攻击路径上的每一个校验/验证函数都已被审查（打开源码、检查边界条件），并给出 SECURE/VULNERABLE 结论。不允许以"候选 A 已能闭环"为由跳过对更底层校验函数（如 proof verification、signature validation、Merkle tree 实现）的源码审查

> **附加停止条件（当触发 Victim-first Gate 时强制）**：必须解释“为何这些第三方会变得可被抽取（可清算/可扣押/被动换仓）”，并把该原因与交易内的可控动作（swap/预言机输入/机制迁移）对齐；否则不允许给出最终 root cause（medium/high）。

---

## 8) 常见误判源（强制规避）

### 8.1 “交易前后差分”不能替代写入对象证据

很多分析工具只能给出**交易前后**的 `stateDiff/storageDiff/prestate(diffMode)`，它们有两个致命盲区：

- **盲区 1（净变化为 0 会消失）**：某个 mapping/槽位在交易内发生了“先加后减/先减后加”，最终回到原值，则前后差分可能看不到该写入；但这不代表“没有发生写入”。
- **盲区 2（无法回答写给谁）**：即使能看到某些槽位变化，也可能无法唯一确定“扣款写入对象（1a）/加款写入对象（1b）”是否与 `to=结算对象` 一致。

因此：

- **禁止**用“差分里没看到 Pair 余额变化”来通过 Write-object-first Gate。
- **允许**把差分仅用于**交叉验证**（例如确认 Pair 的 reserves slot 被写、确认最终利润落点），但闸门结论必须回到“写入对象”级证据。

### 8.2 闸门取证的最低可接受形态（任选其一）

当你怀疑“`transfer(to=结算对象)` 被拦截改写/重定向”时，以下任一类材料可作为闸门证据来源（从强到弱排序）：

- **指令级写入链路**：在 `transfer/transferFrom` 路径中直接定位到 `SSTORE`，并能拆出 **1a 扣款对象** 与 **1b 加款对象**（尤其是硬编码 `PUSH20` 固定地址、或 mapping key 明确可还原）。
- **合约级可还原写入对象**：源码/反汇编能明确展示“收款方被改写为固定地址/条件分支地址”，且能对齐到实际交易调用路径（例如“仅对 Pair/Router 场景触发”）。

> 注意：事件 `Transfer` / 回执 `return 1` / `balanceOf` 输出都只能做定位与验证，不能直接替代闸门证据（见 2.4）。

