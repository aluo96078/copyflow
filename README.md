# ClipFlow

**在 macOS 上重現 Windows 剪貼簿歷程功能。**
**Bring Windows-style clipboard history to macOS.**

---

## 功能 Features

- **Ctrl+V** 開啟剪貼簿歷程面板 / Open clipboard history panel
- **Cmd+C / Cmd+V** 系統複製貼上不受影響 / System copy-paste works as usual
- 自動記錄文字與圖片複製（最多 50 筆）/ Auto-record text & image copies (up to 50 entries)
- 截圖自動存入剪貼簿歷程（不留檔案在磁碟上）/ Screenshots auto-saved to history (no files left on disk)
- 自動停用截圖縮圖預覽以加速偵測，退出時自動恢復 / Auto-disables screenshot thumbnail for faster detection, restores on quit
- 系統列圖示快速操作（暫停/恢復、清除歷程、結束）/ Menu bar icon for quick actions
- 鍵盤導覽：↑↓ 選取、↵ 貼上、Esc 關閉 / Keyboard navigation
- 毛玻璃背景卡片式 UI / Vibrancy blur card-style UI

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
open /Applications/ClipFlow.app
```

`build.sh` 會自動編譯、打包 `.app`、簽名並安裝到 `/Applications`。

`build.sh` will automatically build, package `.app`, sign, and install to `/Applications`.

## 使用方式 Usage

1. 啟動 `ClipFlow.app`（需從 `/Applications` 啟動）
2. 首次啟動會自動打開系統設定，請在「輔助使用」中授權 ClipFlow
3. 按 **Ctrl+V** 開啟剪貼簿歷程
4. 使用 ↑↓ 選取項目，按 ↵ 貼上，按 Esc 關閉

---

1. Launch `ClipFlow.app` (must run from `/Applications`)
2. On first launch, System Settings will open automatically — grant Accessibility permission to ClipFlow
3. Press **Ctrl+V** to open clipboard history
4. Use ↑↓ to select, ↵ to paste, Esc to close

> **注意 Note:** ClipFlow 必須從 `/Applications` 啟動，否則 macOS 輔助使用權限可能無法正常授權。
>
> ClipFlow must be launched from `/Applications` for Accessibility permissions to work correctly on macOS.

## 系統需求 Requirements

- macOS 12.0 (Monterey) 或更高版本 / or later
- 輔助使用權限 / Accessibility permission

## 授權 License

[MIT License](LICENSE)
