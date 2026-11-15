"""Minimal GitHub REST client (stdlib only)."""
import json
import os
import urllib.error
import urllib.request

API = os.environ.get("GITHUB_API_URL", "https://api.github.com")


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k):
        return None


def request(method, path, body=None, raw=False, timeout=30):
    url = path if path.startswith("http") else API + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Accept": "application/vnd.github+json",
        "Authorization": "Bearer " + os.environ.get("GITHUB_TOKEN", ""),
        "X-GitHub-Api-Version": "2022-11-28",
        **({"Content-Type": "application/json"} if data else {}),
    })
    try:
        r = urllib.request.build_opener(_NoRedirect).open(req, timeout=timeout)
    except urllib.error.HTTPError as e:
        # Artifact downloads redirect to blob storage, which must NOT receive our
        # GitHub token (it rejects it with 401): follow the redirect unauthenticated.
        if e.code in (301, 302, 303, 307, 308) and e.headers.get("Location"):
            r = urllib.request.urlopen(e.headers["Location"], timeout=timeout)
        else:
            raise
    with r:
        payload = r.read()
        link = r.headers.get("Link", "")
    return (payload, link) if raw else (json.loads(payload) if payload else None, link)


def paginate(path):
    sep = "&" if "?" in path else "?"
    url = "%s%sper_page=100" % (path, sep)
    while url:
        items, link = request("GET", url)
        for it in items:
            yield it
        url = None
        for part in link.split(","):
            if 'rel="next"' in part:
                url = part[part.index("<") + 1:part.index(">")]
