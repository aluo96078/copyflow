# ClipFlow

**在 macOS 上重現 Windows 剪貼簿歷程功能。**
**Bring Windows-style clipboard history to macOS.**

---

## 功能 Features

- **Ctrl+V** 開啟剪貼簿歷程面板 / Open clipboard history panel
- **Cmd+C / Cmd+V** 系統複製貼上不受影響 / System copy-paste works as usual
- 自動記錄文字與圖片複製 / Auto-record text & image copies
- 截圖自動存入剪貼簿歷程（不留檔案在磁碟上）/ Screenshots auto-saved to history (no files left on disk)
- 系統列圖示快速操作 / Menu bar icon for quick actions
- 鍵盤導覽：↑↓ 選取、↵ 貼上、Esc 關閉 / Keyboard navigation

## 安裝 Installation

### 從 Release 下載 Download from Release

前往 [Releases](../../releases) 下載對應架構的 zip：

- `ClipFlow-apple-silicon.zip` — Apple Silicon (M1/M2/M3/M4)
- `ClipFlow-intel.zip` — Intel Mac

解壓後將 `ClipFlow.app` 拖入「應用程式」資料夾。

Download the zip for your architecture from [Releases](../../releases), unzip, and drag `ClipFlow.app` to Applications.

### 從原始碼編譯 Build from Source

需要 Go 1.24+ 與 Xcode Command Line Tools。

Requires Go 1.24+ and Xcode Command Line Tools.

```bash
git clone https://github.com/YOUR_USERNAME/ClipFlow.git
cd ClipFlow
bash build.sh
open ClipFlow.app
```

## 使用方式 Usage

1. 啟動 `ClipFlow.app`
2. 首次啟動需授予「輔助使用」權限（系統設定 > 隱私權與安全性 > 輔助使用）
3. 按 **Ctrl+V** 開啟剪貼簿歷程
4. 選取項目後自動貼上

---

1. Launch `ClipFlow.app`
2. Grant Accessibility permission on first launch (System Settings > Privacy & Security > Accessibility)
3. Press **Ctrl+V** to open clipboard history
4. Select an item to paste

## 系統需求 Requirements

- macOS 12.0 (Monterey) 或更高版本 / or later
- 輔助使用權限 / Accessibility permission

## 授權 License

[MIT License](LICENSE)
