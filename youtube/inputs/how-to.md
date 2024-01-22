1. Visit your youtube history page searching for your topic of choice:

https://www.youtube.com/feed/history

2. Copy all the URLs to your clipboard

```javascript
copy(Array.from(document.querySelectorAll("ytd-video-renderer a"))
    .map(x => x.href)
    .filter(x => x.includes("watch"))
    .join("\n"))
```

3. Paste into [`input.txt`](./input.txt)