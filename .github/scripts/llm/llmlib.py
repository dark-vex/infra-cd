"""Shared helpers for the LLM PR review (stdlib only).

Used by build_context.py (stage 1, untrusted PR checkout) and by
fetch_context.py / review.py (stage 2, trusted default-branch checkout).
Stage 2 re-applies redaction and path filtering to the artifact because the
artifact is attacker-controlled data.
"""
import re

# Paths whose content must never leave the runner.
_SENSITIVE_PATH = re.compile(
    r"(\.sops\.ya?ml$|(^|/)secrets?\.ya?ml$|(^|/)secrets?/|(^|/)\.env(\.|$)|"
    r"\.(pem|key|crt|cer|p12|pfx|jks|kdbx|tfstate|tfvars|gz|tgz|zip|png|jpe?g|gif|ico|bin|pdf)$|"
    r"(^|/)id_(rsa|ed25519|ecdsa)|\.terraform/)",
    re.IGNORECASE,
)
_SENSITIVE_CONTENT = re.compile(r"ENC\[AES256_GCM|^sops:\s*$|BEGIN [A-Z ]*PRIVATE KEY", re.MULTILINE)

# Public domains that carry useful context and are not infrastructure details.
_PUBLIC_DOMAINS = (
    "github.com", "githubusercontent.com", "github.io", "k8s.io", "kubernetes.io",
    "docker.io", "ghcr.io", "quay.io", "gcr.io", "registry.terraform.io",
    "terraform.io", "hashicorp.com", "helm.sh", "cncf.io", "fluxcd.io",
    "readthedocs.io", "golang.org", "pkg.go.dev", "python.org", "pypi.org",
    "npmjs.com", "gitlab.com", "mozilla.org", "ietf.org", "example.com",
    "example.org", "example.net", "docs.renovatebot.com", "renovatebot.com",
)
_TLDS = (
    "com|net|org|eu|io|it|dev|cloud|local|lan|internal|home|arpa|app|xyz|info|"
    "co|uk|de|fr|nl|ch|us|biz|me|sh|cc|tv|ai|so"
)
_FQDN = re.compile(r"\b(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:%s)\b" % _TLDS, re.IGNORECASE)
_IPV4 = re.compile(r"(?<![\w.])(?<!v)(?:(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}(?:25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})(?![\w.])")

# Built at import time from fragments so this source file does not itself match
# secret scanners (gitleaks rule age-secret-key matches the literal prefix).
_AGE = "AGE-SECRET" + "-KEY-"
_TOKEN_PATTERNS = [
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----", re.DOTALL),
    re.compile(re.escape(_AGE) + r"[A-Z0-9]+"),
    re.compile(r"\bgh[pousr]_[A-Za-z0-9]{20,}"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"\bxox[abprs]-[A-Za-z0-9-]{10,}"),
    re.compile(r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b"),
    re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}"),
    re.compile(r"\bops_[A-Za-z0-9+/=_-]{20,}"),
    re.compile(r"\b[A-Za-z0-9+/_-]{40,}={0,2}\b"),  # long opaque blobs (digests excluded below)
]
_KV_SECRET = re.compile(
    r"(?i)((?:password|passwd|secret|token|api[_-]?key|private[_-]?key|credential)s?[\"']?\s*[:=]\s*[\"']?)([^\s\"',;]{8,})"
)
_DIGEST = re.compile(r"^(sha256|sha512)[:-]?[0-9a-f]{40,}$", re.IGNORECASE)


def is_sensitive_path(path):
    return bool(_SENSITIVE_PATH.search(path))


def has_sensitive_content(text):
    return bool(_SENSITIVE_CONTENT.search(text))


def _fqdn_sub(m):
    host = m.group(0).lower()
    for dom in _PUBLIC_DOMAINS:
        if host == dom or host.endswith("." + dom):
            return m.group(0)
    return "[REDACTED-HOST]"


def _blob_sub(m):
    s = m.group(0)
    # keep git SHAs / image digests (hex only) - useful and not secret
    if re.fullmatch(r"[0-9a-f]{40,64}", s):
        return s
    if re.fullmatch(r"[a-z0-9/_-]+", s):  # all-lowercase path / kebab-case name, not a secret
        return s
    return "[REDACTED-TOKEN]"


def redact(text):
    for pat in _TOKEN_PATTERNS[:-1]:
        text = pat.sub("[REDACTED-TOKEN]", text)
    text = _KV_SECRET.sub(lambda m: m.group(1) + "[REDACTED]", text)
    text = _TOKEN_PATTERNS[-1].sub(_blob_sub, text)
    text = _FQDN.sub(_fqdn_sub, text)
    text = _IPV4.sub("[REDACTED-IP]", text)
    return text


def est_tokens(text):
    """Rough token estimate (chars / 3.5)."""
    return int(len(text) / 3.5) + 1


def truncate_bytes(text, limit, suffix="\n\n_(truncated)_"):
    raw = text.encode("utf-8")
    if len(raw) <= limit:
        return text
    keep = limit - len(suffix.encode("utf-8"))
    return raw[:keep].decode("utf-8", errors="ignore") + suffix


def filter_text(path, text):
    """Return redacted text, or None if the content must be dropped entirely."""
    if is_sensitive_path(path) or has_sensitive_content(text):
        return None
    return redact(text)
