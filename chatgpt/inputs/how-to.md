1. Visit https://chat.openai.com/
2. Open your browser inspector network tab, look for a request like `https://chat.openai.com/backend-api/conversations?offset=0&limit=28&order=updated`
3. Copy it as powershell
4. Paste into [`input.txt`](./input.txt)

```pwsh
./pull_convo_list.ps1
./build_download_list.ps1
./pull_convo_contents.ps1
```

# Inspecting JWTs

[CyberChef](https://gchq.github.io/CyberChef/) ([GitHub](https://github.com/gchq/CyberChef)) can be ran locally, which is better than building a habit around tools jwt.io.