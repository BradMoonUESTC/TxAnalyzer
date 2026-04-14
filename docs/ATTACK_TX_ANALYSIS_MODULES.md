## 模块化附录（可选但推荐）

> 目的：把“高频但容易漏”的攻击机制抽成独立模块，避免主流程过载。  
> 使用方式：当你在交易里命中触发条件，就把对应模块当作“强制检查清单”执行，并把结果写回阶段 2/3/5 的闭环里。

---

## 模块 A：批量清算驱动型攻击（Liquidation-driven Extraction）

### 触发条件（任一命中）
- `users_to_liquidate()` 返回多个地址，或出现对多个 `victim` 的 `liquidate(victim, ...)`
- 同一笔 tx 内对大量第三方地址执行“结算/扣押/强制换仓”

### 你必须回答的 3 个问题（LLM 友好）
1) **谁是受害者？**（至少 3 个地址样例）  
2) **价值怎么被抽走？**（清算/扣押/罚金/强制换仓）  
3) **他们为什么会同时变差？**（同一条可控输入、同一套机制、同一段时序）

### 最短证据要求
- 受害者集合来自 trace 参数/返回值（而不是凭感觉）
- 至少给出 1 条“资产从头寸/AMM 写出到清算器/攻击者”的转移锚点

---

## 模块 B：ERC4626 share 定价操纵（Assets 旋钮 + Supply 旋钮）

### 触发条件（任一命中）
- oracle/健康度输入使用 `convertToAssets/convertToShares`
- share 兑换率在同一 tx 内突变

### 强制三问
1) **是 `totalAssets` 变了，还是 `totalSupply` 变了，还是两者都变了？**  
2) **变化入口是什么？**（donation/第三方记账 vs `deposit|mint|withdraw|redeem`）  
3) **该变化如何进入 oracle/健康度判定？**（谁读、读到什么）

### 常见漏点（必须显式排查）
- 只看 donation（assets 旋钮）但漏掉 `redeem`（supply 旋钮）
- 只看 share 兑换率跳变，但没把它“投喂”到清算判定的那次读取锚定出来

---

## 模块 F：ERC4626 Supply 旋钮证据化（redeem/mint/deposit/withdraw）

> 目标：把 “redeem 影响 totalSupply” 从推断变成可复核证据；同时保持通用（适用于任意 ERC4626/share token）。

### 触发条件（任一命中）
- 你在叙事中提到 `redeem/withdraw/mint/deposit` 会影响 share 定价/清算输入
- 或者你声称“使用了 supply 旋钮（totalSupply 变化）”作为攻击链的一部分

### 强制输出（必须全部给出）
- `supply_ops`: 列出本 tx 内所有与 share supply 相关的调用（至少包含 `redeem/withdraw/mint/deposit` 中命中的项）
  - 每条包含：`trace_anchor`、`method`、`shares_or_assets_amount`（尽量从 decoded_input/output 或紧邻 Transfer 推断）
- `totalSupply_before_after`：给出 **同一 tx 内** `totalSupply()` 至少两次读取锚点：
  - `before_anchor` / `before_value`
  - `after_anchor` / `after_value`
  - 并解释它们在时间顺序上与 `supply_ops` 的关系（读在操作前/后）

### 允许的最小证据来源（从强到弱）
1) 直接的 `totalSupply()` 调用输出（同 tx 前后）
2) share `Transfer`/`Burn`/`Mint`（若合约实现标准且可对齐）
3) 若无法获取 before/after（trace 缺失）：必须明确写为“未证据化”，并把它列为最短补证动作（不得把 supply 旋钮写成确定性根因）

---

## 模块 C：大额 swap 推动 + 机制迁移（Banded AMM/LLAMMA 类）

### 触发条件（任一命中）
- 协议组件包含 banded AMM/LLAMMA/分段机制（或 trace 中出现其 `exchange/active_band/user_tick` 等函数）
- 出现批量清算或大量第三方同时变差

### 强制输出字段（用于写入 Degradation Chain）
- `push_action`: 哪次 swap/exchange 推进了价格/池子比例（给 trace 锚点）
- `mechanism_action`: 哪次内部机制调用发生了迁移/换仓（给 trace 锚点）
- `downstream_effect`: 迁移如何影响健康度/清算判定（解释即可，不要求全复算）

### 最短证据要求
- 至少列出 1 个外部 swap/exchange 锚点（池子/Router）
- 至少列出 1 个机制内 `exchange` 或 band 相关调用锚点（AMM/LLAMMA/Controller）

---

## 模块 G：清算前“被动迁移/换仓”证据化（Position Migration Before Liquidation）

> 目标：避免把“清算结算动作（withdraw）”误写成“清算前导致变差的迁移动作”。  
> 该模块通用于：banded AMM/LLAMMA、自动再平衡抵押、分段机制、或任何“头寸会被价格推进驱动迁移”的系统。

### 触发条件（任一命中）
- 你在结论/叙事中提到“bands/机制导致头寸被动换仓/迁移/敞口变化”
- 或者出现批量清算且你需要解释“为什么会同时变差”

### 强制输出（必须全部给出）
- `liquidation_anchor`: `users_to_liquidate()` 或第一次 `liquidate(victim)` 的 trace 锚点（用作时间分界）
- `pre_liq_mechanism_calls`: 至少 2 条**发生在 liquidation_anchor 之前**的机制相关调用锚点（不能是 `withdraw(victim,1e18)` 这类清算内部结算）：
  - 允许的候选包括：AMM/机制的 `exchange`、band/tick/position 读取（如 `read_user_tick_numbers(user)`、`get_sum_xy(user)`、`callback_user_shares(user,...)` 等）、`active_band`/band 边界推进函数等
- `victim_specific_evidence`: 从 victims 中任选 1 个地址，找到至少 1 条清算前**直接包含该 victim 地址作为参数**的机制调用锚点（证明迁移/判定与该 victim 的头寸相关，而不是纯全局叙事）
- `migration_effect`: 用 1-2 句解释“迁移如何让健康度更差”（例如抵押构成偏移、可清算区间跨线），不要求全复算，但必须能对应到上面的锚点与时间顺序

### 禁止事项
- 禁止只引用“清算后/清算内部”的 `withdraw`/`transferFrom` 来证明“清算前迁移发生了”。
- 禁止在缺少 `victim_specific_evidence` 时把“bands 被动换仓导致变差”写成确定性主因（最多 medium，并列最短补证动作）。

---

## 模块 D：Swap 发现与归因（通用、强制给 Top 列表）

> 目标：避免“没看到就当不存在”，以及避免把内部结算动作误当 swap 推进动作。

### 触发条件（任一命中）
- 出现批量清算/大量第三方同时变差
- 出现 oracle 输入（pool price / redemption rate / aggregator）突变

### 强制输出
- `top_swaps`（Top-3，按输入量排序，每条必须包含）：
  - `trace_anchor`：对应 trace 文件/索引
  - `callee`：池子/Router 地址
  - `method`：swap/exchange 的函数名（来自 decoded_input）
  - `amount_in` / `amount_out`：尽量从 decoded_input 或紧邻转账推断
  - `path_or_ij`：Uniswap path 或 Curve i/j（若可得）
- `swap_to_oracle_link`：用 1-2 句说明这些 swap 中哪一个最可能影响 oracle 输入，以及理由（时间顺序 + 输入组件对齐）。

### 允许的最小证据来源（从强到弱）
1) `decoded_input` 直接给出 amount 参数  
2) 该调用子树内紧邻的 ERC20 `Transfer` 金额（amount_in/amount_out）  
3) 若两者都缺失：只能写“无法从现有 trace 直接取到 amount”，并把它列为“最短补证动作”（不得直接否定 swap 的存在）

---

## 模块 E：池子 coin 解析（把 i/j/path 落到具体 token）

> 目标：让“在 alUSD-sDOLA 池大额 swap”这类结论可复核、可复述，而不是停留在“某 Curve 池 i/j”。

### 触发条件（任一命中）
- `top_swaps` 中出现 Curve 风格 `exchange(i,j,...)` / `exchange_underlying(i,j,...)` / `remove_liquidity_one_coin(coin_index,...)`
- 或者分析中出现“某池 swap 改变了池内资产比例/推动价格”的叙述

### 强制输出（每个命中的 swap 都要输出）
- `pool`: 池子地址
- `method`: 具体方法名（exchange/exchange_underlying/...）
- `i/j` 或 `coin_index`
- `in_token` / `out_token`：必须输出 token 地址；若能从 trace/合约源码推断符号（alUSD/sDOLA/crvUSD…）可附加 `symbol`
- `evidence`: 用 1-2 条锚点说明你是怎么解析出来的（任选其一即可）：
  1) **trace 内部静态调用**：例如同一 tx 内对 pool 的 `coins(i)` / `underlying_coins(i)` / `N_COINS()` / `get_balances()` 调用结果  
  2) **紧邻 Transfer 推断**：在该 swap 子树内，观察到 `tokenX.transferFrom(attacker->pool, amount_in)` 与 `tokenY.transfer(pool->attacker, amount_out)`  
  3) **源码/ABI 佐证**：合约源码/ABI 表明 coin 索引含义 + 与 (1)(2) 对齐

### 禁止事项
- 禁止只写“Curve metapool / StableSwapNG”而不解析 coin（这会导致结论无法落到“alUSD-sDOLA”这种可核对描述）。
- 禁止在缺少 coin 解析证据时直接声称“该池就是 X-Y 池”；应降级为“候选池”，并列出最短补证动作（例如去 trace 搜 `coins(` / 看 swap 子树转账）。

---

## 模块 H：多机制业务链与累计桶 flush（Business-logic Composition）

> 目标：覆盖“每个机制单独看像正常业务，但攻击者在同一笔 tx 内把它们串起来，对同一状态桶/结算对象叠加生效”的场景。  
> 常见于：deflationary token、reward distributor、fee bucket、延迟结算、公开 maintenance/flush/sync 入口。

### 触发条件（任一命中）
- 同一合约在单 tx 内被**重复调用 3 次以上**，且函数职责不同（例如 `deposit/claim/sell/flush/distribute/sync`）
- 出现 `pending/reward/fee/burn/debt/distributor` 这类**累计态 / 延迟结算态**
- 存在公开 `flush/claim/settle/distribute/sync` 入口，能把累计态立即作用到 Pair/Vault/Oracle/黑洞地址
- 同一结算对象（Pair/Vault/Router/Distributor/Dead address）被多条机制共同触达

### 强制五问
1) **共享状态桶是什么？**  
   谁增加它，谁清空它，谁读取它？
2) **共享结算对象是什么？**  
   每条机制如何作用到它（改余额/改储备/改份额/改价格输入）？
3) **哪些输入负责“选中分支”？**  
   至少显式检查 `from/to/receiver/path/msg.sender/tx.origin`，看是否命中特殊接收者或特殊路径。
4) **为什么这些机制能在单 tx 内串联？**  
   是公开可达、缺 access control、缺 cooldown/epoch、还是原子化调用顺序可控？
5) **最后一跳盈利动作是什么？**  
   它是在“直接制造漏洞”，还是仅仅把前面造出的异常状态变现？

### 强制输出字段
- `phase_map`: 至少把主干路径标成 `finance/setup/accumulate/flush/extract/repay` 中命中的阶段
- `shared_state_bucket`: 例如 `pending burn` / `reward debt` / `fee bucket` / `distributor credit`
- `mechanisms`: 至少列出 2 条机制，每条包含：
  - `entry`: 入口函数/动作
  - `effect_on_bucket_or_object`: 它改变了哪个共享状态桶或结算对象
  - `trace_anchor`: 对应 trace 锚点
- `branch_selector_inputs`: 触发特殊分支的输入（如 `to=router`、`receiver=router`、`path[i]=tokenX`）
- `flush_or_settlement_action`: 哪个动作把累计态真正落到结算对象/黑洞/储备/价格输入上
- `extraction_action`: 最终如何把异常状态变成利润（swap/redeem/withdraw/liquidate）
- `why_composable_in_one_tx`: 用 1-2 句解释“为何攻击者能把这些机制原子化串联”

### 最短证据要求
- 至少有 1 个 `shared_state_bucket` 或 `shared_settlement_object`
- 至少有 2 条不同机制的 trace 锚点，且二者都能对齐到同一个 bucket/object
- 若叙事涉及特殊接收者/路径分支，必须给出实际输入值，而不是只写“命中了特殊分支”

### 禁止事项
- 禁止只把最后一跳 `swap/redeem/withdraw` 写成 root cause，而不解释前序如何制造异常状态
- 禁止把会改变 `shared_state_bucket` 或同一结算对象的步骤一概写成“只是准备动作”
- 禁止在没有 `why_composable_in_one_tx` 的情况下，把“多机制链式利用”写成 high-confidence 结论

---

## 模块 I：跨链桥 / Proof Verification / 消息鉴权攻击

### 触发条件（任一命中）
- trace 中出现跨链消息处理函数（`handlePostRequests`、`dispatchIncoming`、`onAccept`、`receiveMessage`、`executeMessage`、`verifyAndDeliver` 等）
- 攻击路径涉及 proof/Merkle 验证（`verifyProof`、`calculateRoot`、`processProof`、`MerkleMultiProof`、`MMR` 等）
- 攻击者通过跨链消息触发了目标链上的权限变更、铸币、资产转移等高权限动作

### 你必须回答的 5 个问题（按顺序，不可跳过）

1) **消息是怎么进入系统的？** 画出完整调用链：`攻击者 → handler → host/dispatcher → 应用模块`，标注每一层做了什么校验

2) **Proof verification 的实现是否正确？**（必须打开完整源码逐行审查）
   - 逐行检查以下边界条件：
     - `leaf_index >= leafCount` 是否被拒绝？（若不拒绝，proof 路径可能跳过 leaf，导致任意 request 通过验证）
     - `proof.length == 0` 或 `leaves.length == 0` 是否被拒绝？
     - 循环是否会因边界条件被跳过（导致 leaf 不参与 root 计算）？
   - 核心判定：**修改 request 任何字段后，proof verification 是否一定失败？** 如果不一定 → 绑定断裂 → VULNERABLE

3) **Message hash/commitment 是否绑定了所有关键字段？**
   - 找到 `message.hash()` / `commitment = keccak256(abi.encode(...))` 的实现，确认 `from`、`to`、`body`、`nonce` 是否都被纳入

4) **应用层鉴权是否足够？**
   - 是否存在"链级别鉴权"（`source == trustedChain`）但缺少"发送者级别鉴权"（`from == trustedModule`）？

5) **哪一层是真正的 root cause？**
   - proof verification 有 bug → proof verification 是 root cause（即使应用层也有缺陷）
   - proof 正确但应用层鉴权不足 → 应用层是 root cause
   - 两者都有独立 bug → 两个都是 root cause

### 强制输出
- `trust_boundary_chain`: 每一层校验函数 + SECURE/VULNERABLE 结论
- `proof_verification_audit`: proof 函数源码边界条件检查结果
- `deepest_root_cause`: 最底层代码缺陷，精确到文件名+行号

### 禁止事项
- **禁止以"攻击者可以在源链合法发送消息"为由跳过 proof verification 审查**
- **禁止以"候选 A 已能闭环"为由不检查 proof verification 代码**
- **禁止把 proof verification 标为 SECURE 而不给出具体的边界条件检查证据**
