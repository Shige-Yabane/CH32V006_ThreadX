# CH32V006F8P7 ThreadX RV32E 検証済み基底プロジェクト

このディレクトリは、CH32V006F8P7（QingKe V2C）向けに作成した
ThreadXのC言語用ポーティング基底です。`RTOS_Testmain`で実機検証した
RV32Eポートと同一のCPU依存部を収録しています。MounRiver Studioへ
`Existing Projects into Workspace` でインポートできます。

## CPU／メモリ設定

- MCU: CH32V006F8P7
- ISA: `-march=rv32ecxw`
- ABI: `-mabi=ilp32e`
- Flash: `0x00000000`から62 KiB
- SRAM: `0x20000000`から8 KiB
- リンカスクリプト: `Ld/Link.ld`
- `TX_MINIMUM_STACK`: 256バイト（ポート既定値）
- `TX_TIMER_THREAD_STACK_SIZE`: 512バイト（ポート既定値）

`.cproject` は、公式CH32V006 SDKのCプロジェクト設定を基にしています。
RV32Eではx0～x15だけが使用可能なため、CH32V203用RV32Iポートの
x16～x31を使用する保存／復元コードは流用していません。

## ディレクトリ

- `AzureRTOS/common/`: ThreadX共通ソースと公開ヘッダー
- `AzureRTOS/ports/risc-v32/common/`: RISC-V共通ポート定義
- `AzureRTOS/ports/risc-v32/gnu/`: CH32V006 RV32E用GNUポート
- `Startup/`: WCH起動コードとThreadX Software IRQラッパー
- `User/`: main1 LED再検証プログラム、HardFault診断、SysTick初期化
- `Ld/`: CH32V006の62 KiB Flash／8 KiB SRAM用リンク設定
- `Core/`, `Peripheral/`: OpenWCH公式CH32V006 SDKのデバイスサポート

## `AzureRTOS`へ入れる範囲

この基底プロジェクトの`AzureRTOS`には、アプリケーションのビルドに必要な
ThreadX本体だけを置く。CH32V006の実アプリケーションへそのままコピーできる
構成とし、完全な
ThreadX配布物をプロジェクトへコピーしない。

- `common/inc/`：ThreadX公開ヘッダー
- `common/src/`：単一コアThreadXカーネルと各API実装
- `ports/risc-v32/common/`：RISC-V共通ポート定義
- `ports/risc-v32/gnu/inc/`および`src/`：CH32V006 RV32E用のGNUポート

`docs`、`samples`、`test`、`utility`、`cmake`、`common_modules`、SMP／module用の
ソース、他CPU／他コンパイラ向けの`ports`は入れない。これらを含む完全なThreadX
配布ツリーは、必要時に参照するだけでビルド対象にはしない。

`common/src`は将来使用するThreadX APIも含む単一コアカーネル本体である。これは
CH32V006の基底プロジェクトとして、未参照の関数は
`-ffunction-sections`とリンカの`--gc-sections`により実行イメージから除外される。

### 共通部に加えたCH32V006固有の変更

`AzureRTOS/common`は原則オリジナルのThreadXを保持しているが、次の3ファイルだけは
CH32V006移植用に変更している。

- `tx_thread_system_resume.c`：アイドル状態で`current_thread`が`TX_NULL`の場合の
  不正なシステム復帰を防止する判定。動作上必要。
- `tx_thread_shell_entry.c`：初回スレッド復帰を確認する診断変数。デバッグ専用。
- `tx_timer_thread_entry.c`：タイマースレッド進行を確認する診断変数。デバッグ専用。

他CPUへ移植する場合、前者は対象CPUのアイドル時割り込み復帰経路を確認してから採用し、
後者2つはWatch診断が不要なら省略できる。

## CPU依存実装の要点

`AzureRTOS/ports/risc-v32/gnu/src` の保存フレームはRV32E専用です。

- 割り込み／初回起動フレーム: 20ワード（80バイト）
- ThreadXサービスからの復帰フレーム: 20ワード（80バイト）
- 保存対象: `ra`, `gp`, `tp`, `t0`～`t2`, `s0`～`s1`,
  `a0`～`a5`, `mepc`, `mstatus`
- SysTickとSoftware IRQは`Startup/tx_vector_wrappers.S`から同じ
  `context_save`／`context_restore`経路へ入ります。
- ISRで別スレッドが実行可能になった場合は、割り込み復帰中であることを
  `_threadx_interrupt_return_active`で記録し、休止中スレッドの短いフレームを
  `ret`ではなく`mret`で復帰させます。

## 初回ビルドとmain1最終確認

コピー後はMounRiver Studioで **Project → Clean** を実行してからBuildします。
`User/main.c`はPD4をアクティブHighのテストLED出力に使用します。PA1-XIN／PA2-XOUTの
24 MHz水晶と48 MHz PLLを前提とします。基板のLEDが別ピンの場合は、
`LED_GPIO_PORT`と`LED_GPIO_PIN`を変更してください。

実行後、LEDが約0.5秒ごとに反転し、次の変数をデバッガーで確認します。

| 変数 | 正常値／意味 |
|---|---|
| `main1_test_magic` | `0x4D315246` |
| `main1_thread_create_count` | `1` |
| `main1_sleep_request_count` | 継続して増加 |
| `main1_sleep_resume_count` | 継続して増加。requestとの差は最大1 |
| `main1_led_toggle_count` | 継続して増加（約2回/秒） |
| `main1_error_count` | `0` |
| `main1_last_status` | `0`（`TX_SUCCESS`） |
| `tx_diag_fault_seen` | `0` |

HardFaultで停止した場合は、`tx_diag_fault_mcause`、`tx_diag_fault_mepc`、
`tx_diag_fault_mtval`、`tx_diag_fault_mstatus`を確認できます。

このmain1は、512バイトのLEDタスクスタックで50 tick（約0.5秒）ごとに
`tx_thread_sleep()`から復帰します。従って、自発的中断、SysTick、Software IRQ、
スケジューラ、および`mret`復帰を連続して確認できます。

アプリケーション側の各`ULONG`スタック配列は`__attribute__((aligned(16)))`で
16バイト境界へ明示配置します。ポート側も上端を16バイトへ丸めるが、宣言側で
揃えることで容量の切り捨てを防ぎます。

## 検証済みポートの前提

- WCHハードウェアスタックと`WCH-Interrupt-fast`をThreadXの切替経路では使用しない
- `CSR 0x804 = 0`としてHWSTKENと割り込みネストを無効化する
- RV32Eの完全フレームは20ワード（80バイト）、16バイト境界とする
- 検証済みの初期化処理は`User/tx_port_ch32v006.c`の
  `_tx_initialize_low_level()`へ移した。`Startup/tx_initialize_low_level.S`は、
  旧MounRiver生成makefileとの互換用に残す場合でも、シンボルを定義しない空スタブにする
- ThreadX本体にある`ports/risc-v32/gnu/src/tx_initialize_low_level.S`は、
  一般的なRISC-V GNUポート用であり、CH32V006のRV32Eレジスタ構成、WCHのPFIC／
  SysTick、Software IRQ、システム／ISRスタック配置と一致しないため使用しない。
  そのまま流用するとコンテキストフレームや割り込み復帰と不整合になるため、
  CH32V006専用の`User/tx_port_ch32v006.c`へ置き換えている
- mainタスク512バイト、ThreadXタイマースレッド512バイト、
  ThreadXシステム／ISRスタック512バイトを確保する
- 上記3領域のシステムタスク用スタック合計は1536バイトであり、ワーカースレッド、
  TCB、カーネルオブジェクトとは別にRAM使用量へ加算する

`User/tx_user.h`は現行構成では使用していません。ユーザー設定でポート既定値を
上書きする場合だけ、`TX_INCLUDE_USER_DEFINE_FILE`と実際の設定ヘッダーを併せて
追加してください。
