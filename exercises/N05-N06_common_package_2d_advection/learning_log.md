# N05-N06 学習ログ

## N05：抽出前の予想とbaseline

- 残す挙動・実際の重複・N04選択：N01ーN04の更新配列，端点・周期境界の規約，引数と戻り値，診断・描画・初期条件を保ち，隣接添字・流束・バッファ検証・時間刻み調整と更新式を共通側へ移す．N04選択は`:nonlinear`（`867205c8`）．
- baselineを取得したcommitと対象コード：抽出前commit `bef4ed2c57edffc3a467812f43a888b0db6c2f69` で `N05.jl baseline` を実行．N01ーN04の既存run.jlの代表結果を新しいJuliaプロセスで取得した．

## N05：採用したdiffと回帰

- 共通APIへ移した処理と，課題に残した処理：`src/ThermofluidExercise.jl`に周期添字，線形/Burgers流束，バッファ検証，刻み調整を実装し，N01ーN04の既存入口から共通更新・境界処理を呼ぶ．各課題の初期条件，実験条件，診断，描画，保存は課題側に残した．N04の更新には`SELECTED_MODEL`を明示して渡す．
- テスト・代表結果の差とその理由：F01（3/3），F02（10/10），F03-F04（16/16），N01（13/13），N02（25/25），N03（20/20），N04（15/15），N05共通API（21/21）が成功．baseline比較も成功し，11,493個の浮動小数比較で最大差は0.0．baselineのSHA-256は`8873c5ea998f510c9761c79303aeed21f0bb40488f5cc31b1b584ab99a7cda57`，baseline時の`src/ThermofluidExercise.jl`は`af4d85746362897f4bed77dda0b395504b867a3fdb504af55d70aecb029152e8`，現在は`262e62b69cb82e79b762ac549a8e06aa87630743bc95df575797ef536786b970`．詳細は`results/N05/regression.toml`．
- AI提案の採否・復帰支援：共通関数へ委譲する差分を採用し，差分・既存テスト・baseline結果を照合した．テストの整合性を確認．コードの誤りの修正およびトラブルシューティング．復帰支援は利用していない．
- 復帰点を使った場合の採用差分と説明：

## N06：二次元更新と数値検証

- 軸・周期端・角・方向別寄与・合成CFL：`u[i,j]`の第1添字をx，第2添字をyとし，両軸の左隣を周期接続して同じ旧行列から全点を更新した．角もx・y双方の寄与を受ける．上限は`safety/(cx/dx+cy/dy)`，1ステップのCFLは`cx*dt/dx+cy*dt/dy`．出力前に形状・alias・有限値・合成CFLを検査する．
- 複数ステップの保存量，自作テスト：5×4の非対称・非定数行列を30ステップ更新し，`dx*dy*sum(u)`を初期場から独立に計算した．丸め誤差を考慮し`rtol=0, atol=1e-12*max(1,abs(initial_mass))`で比較した．合計値の保存はこの格子・条件での離散保存を確認するが，局所解の物理的正しさまでは保証しない．
- 3格子の誤差・観測次数と考察：最終時刻のRMS型L2誤差は`[0.04586691138478507, 0.02406462411492619, 0.012332831539922874]`，観測次数は`[0.9305398727322467, 0.9644098174384694]`で，格子を細かくすると誤差が減少し両区間で約1次となった．一次上流差分と前進Eulerの数値拡散を含む一次精度と整合する．

## N06：保存場の再解析と再作図

- 分散を追加した結果，HDF5の変更前後のSHA-256：`spatial_variance`は各場の平均から母分散を計算し`Float64`で返す．`diagnostics_complete=true`．最終成果物の`fields.h5` SHA-256は`6a7fb09ef4985ef91a630e27b5dba4b1f3b68983751161e533f8c2f95133f4ee`．再解析前後も同じSHA-256で，保存場は変更されていない．
- 表示設定の変更，入力HDF5・summaryのSHA-256：カラーマップを`:plasma`，共通場の色範囲を`(0.3,1.7)`，表示格子を`n080x060`に変更し，数値解・初期場・解析解を同じ色範囲で再作図した．`plots.toml`の入力HDF5 SHA-256は上記と一致し，summary SHA-256は`1c606474bc3f0206265c56d4cfb8e1784e0a387c1ea6c711c939d2f0fdc2cf78`．
- 保存されなかった時刻からは求められない量：HDF5には`t=0,0.25,0.5,0.75,1`のみ保存されるため，保存時刻間の瞬時場・その分散や誤差の時間推移を後から直接復元できない．

## 理解度チェック・提出前確認

- N05・N06それぞれの理解度チェックと振り返り：理解度チェック対話全文（`understanding-check-N05.txt`，`understanding-check-N06.txt`）をLETUSに提出済み．

- 実行コマンド，テスト結果，成果物，未解決事項：`julia --startup-file=no --project=. exercises/N05-N06_common_package_2d_advection/run.jl`でN05回帰からN06の6出力まで一括生成ができることを確認．N05-N06テストはすべて成功（共通API21，N06配布済み10，自作保存量2・収束3・分散3，出力・出自4）．進捗連動テスト`julia --startup-file=no --project=. test/runtests.jl`も199件の共通検査とF01ーN05-N06を含めすべて成功．出力は`results/N05/`と`results/N06/`．

## origin/main統合とPR競合解消

- 統合元と解消方針：更新された`origin/main`（`40f06304b7d81fc8cf0e5dfc7029edc0747fc204`）を取り込み，N02-N04入口の共通API委譲，N06実装・設定・テストを保持して競合を解消した．既存の説明コメント・テストを残し，重複する更新処理は共通実装に一本化した．merge commitは`447727877cc7a9455f2c2188bbb10b0a843bc4d8`．
- 再検証：`julia --startup-file=no --project=. exercises/N05-N06_common_package_2d_advection/N05.jl verify`成功．baseline SHA-256は`8873c5ea998f510c9761c79303aeed21f0bb40488f5cc31b1b584ab99a7cda57`のまま維持し，11,493個の浮動小数比較の最大差は0.0．更新後の`src/ThermofluidExercise.jl` SHA-256は`e5706ee4c0ef1199729e1fb620cba9d4de982d988c1eea8b27e11aec8dbaf577`．
- 統合後の進捗連動テスト：`julia --startup-file=no --project=. test/runtests.jl`成功（共通199，F01 3，F02 10，F03-F04 16，N01 13，N02 25，N03 20，N04 15，N05-N06 43件）．
