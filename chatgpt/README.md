# Horobi Transcript Utility - ChatGPT

I want to search my full chat history with ChatGPT.

Using OpenAI's GDPR export, we can get a lot of our data without hammering the API.

However, conversation updates after the export must be fetched from the website.

- [`get_latest_backup.ps1`](.\get_latest_backup.ps1) - Find the latest zip file from GDPR export
- [`get_backup_conversations.ps1`](.\get_backup_conversations.ps1) - Extract conversations.json from the zip file
- [`ensure_backup_on_disk.ps1`](.\ensure_backup_on_disk.ps1) - Helper to ensure the backup is on disk; download w/ OneDrive
- [`pull_convo_list.ps1`](.\pull_convo_list.ps1) - get the list of conversation IDs and updated timestamps
- [`build_download_list.ps1`](.\build_download_list.ps1) - retain only the IDs of conversations updated after the export
- [`pull_convo_contents.ps1`](.\pull_convo_contents.ps1) - download conversation jsons
- [`expand_backup_conversations.ps1`](.\expand_backup_conversations.ps1) - unused at this time
