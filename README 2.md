# PASSAGE 個人雲端繁體中文版本（第一版原型）

這是一個可以部署和接上 Supabase 的**原型**，不是已上線的服務；原始 `engine.html` 原封不動保留，沒有重新簽章或修改題庫。

## 目前有什麼
- 登入、註冊、Email 驗證（依 Supabase 專案設定）
- Supabase PostgreSQL Row Level Security：只允許帳號讀取自己的雲端紀錄；寫入走檢查版本號的 RPC
- 上傳 Local Storage 與 IndexedDB 以 `zyz`、`ielts-reading`、`passage` 為前綴的資料；登入時先取雲端紀錄，**在原引擎啟動前**還原
- 每 25 秒自動嘗試同步；亦有「立即同步」「從雲端還原」
- 透過 ICU 漢簡→漢繁字元字典，在原本的 iframe 可存取的情況下動態將可見中文字及 UI 提示轉為繁體（不是人工逐句校對）

## 設定
1. 登入 https://supabase.com 建立自己的專案。到 **SQL Editor** 執行 `supabase.sql`。
2. 到 Project Settings / API 找 **Project URL** 以及 `anon` 或 publishable key。複製 `config.example.js` 為 `config.js`，填入兩項。**不要**貼入 `service_role` / secret key。
3. 到 Authentication 設定註冊方式；如使用 Email 驗證，記得設定 Site URL 與 Redirect URL。
4. 把整個資料夾部署到同一 HTTPS 來源，例如 Netlify、Cloudflare Pages 或 GitHub Pages（注意檔案 49MB；部份平台的單檔限制可能不允許，改用可支援大檔的主機）。
5. 於不同電腦開啟相同網址，登入同一 Email 帳號，先等頁首出現「已同步」再切換裝置。

## 重要限制
- **尚未通過真實瀏覽器端到端測試**；特別是原版含簽章／巢狀 iframe，需確認在 HTTPS 託管、iframe 存取與資料還原時均正常。原引擎可能限制外部注入，本原型不突破簽章。
- 不保證 UI 每個用詞已台灣在地化（例如「質量」等語境依詞彙意義不同），須人工 QA。題庫英文原文不變。
- 跨裝置**同步練習紀錄**，但沒有即時協同編輯。不要在兩台裝置同時操作同一份未完成作答；遇版本衝突會停止上傳。
- 本實作採「整份快照」儲存，Supabase SQL 設定 5MB 上限；長期大量作答需要改成**逐筆增量同步**，也應加入合併策略、可恢復的匯入交易與詳盡自動化測試。
- 當另一台裝置已登入且更新，已開啟的舊裝置不會自動重載遠端進度；會在下一次上傳偵測到版本衝突並拒絕覆寫。
- 讀取快照依 `indexedDB.databases()`：不支援此 API 的瀏覽器只涵蓋程式內已知的紀錄庫名，其他資料庫可能漏同步。
- 本機既有資料和雲端資料碰撞時，原型不做自動合併；**請先各自匯出原版完整備份。** 取消覆寫會停止登入練習。
- 不建議先把正式使用者資料導入此原型，直到完成隔離環境測試。
- 確認你具有修改、重新部署題庫及文章內容所需的使用權限。
