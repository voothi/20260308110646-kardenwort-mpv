## 1. Project Setup

- [ ] 1.1 Create `scripts/_tools/youtube-downloader/` directory structure
- [ ] 1.2 Add `__init__.py` to make it a Python package
- [ ] 1.3 Create `youtube_downloader.py` main script

## 2. Configuration

- [ ] 2.1 Add `youtube_download_resolution` configuration option (default: "1080p")
- [ ] 2.2 Add `youtube_download_directory` configuration option (default: user's Videos folder)
- [ ] 2.3 Add `youtube_download_backend` configuration option (default: "yt-dlp")
- [ ] 2.4 Add `youtube_download_overwrite` configuration option (default: false)
- [ ] 2.5 Update `mpv.conf` with commented examples for YouTube download settings

## 3. YouTube URL Detection

- [ ] 3.1 Implement YouTube URL regex pattern matching
- [ ] 3.2 Support youtube.com URL format
- [ ] 3.3 Support youtu.be short URL format
- [ ] 3.4 Implement file reading and URL extraction
- [ ] 3.5 Add error handling for files with no YouTube URLs

## 4. Download Backend Implementation

- [ ] 4.1 Implement yt-dlp backend integration
- [ ] 4.2 Implement youtube-dl-gui backend integration
- [ ] 4.3 Implement newpipe backend integration
- [ ] 4.4 Implement asbplayer backend integration
- [ ] 4.5 Add backend availability checking
- [ ] 4.6 Add backend selection logic based on configuration

## 5. Download Functionality

- [ ] 5.1 Implement video download with resolution selection
- [ ] 5.2 Implement resolution fallback when requested resolution is unavailable
- [ ] 5.3 Implement directory creation if target directory doesn't exist
- [ ] 5.4 Implement directory write permission checking
- [ ] 5.5 Implement existing file handling (skip or overwrite based on config)
- [ ] 5.6 Add download progress tracking and display

## 6. Windows "Send to" Integration

- [ ] 6.1 Create Windows batch script or PowerShell script for "Send to" integration
- [ ] 6.2 Create shortcut in Windows "Send to" folder
- [ ] 6.3 Test "Send to" integration with single file
- [ ] 6.4 Test "Send to" integration with multiple files

## 7. Error Handling and Logging

- [ ] 7.1 Implement error handling for download failures
- [ ] 7.2 Implement error handling for missing backends
- [ ] 7.3 Implement error handling for network issues
- [ ] 7.4 Add logging for download operations
- [ ] 7.5 Add user-friendly error messages

## 8. Documentation

- [ ] 8.1 Create README for youtube-downloader tool
- [ ] 8.2 Document configuration options
- [ ] 8.3 Document "Send to" integration setup
- [ ] 8.4 Document supported backends and their requirements
- [ ] 8.5 Add usage examples

## 9. Testing

- [ ] 9.1 Add acceptance test for YouTube URL detection
- [ ] 9.2 Add acceptance test for single URL download
- [ ] 9.3 Add acceptance test for multiple URL download
- [ ] 9.4 Add acceptance test for resolution configuration
- [ ] 9.5 Add acceptance test for directory configuration
- [ ] 9.6 Add acceptance test for backend selection
- [ ] 9.7 Add acceptance test for existing file handling
- [ ] 9.8 Add acceptance test for error scenarios (no URL, missing backend, etc.)

## 10. Integration and Polish

- [ ] 10.1 Test integration with existing TSV workflow
- [ ] 10.2 Verify no interference with existing mpv functionality
- [ ] 10.3 Performance testing for large batches of downloads
- [ ] 10.4 Code review and cleanup