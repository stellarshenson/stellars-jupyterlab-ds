"""Response rewriter for the rmonitor (ttyd/btop) server-proxy entry.

ttyd sizes its xterm terminal once at startup, before the renderer's font
metrics settle - the early fit measures wider character cells and computes too
few columns, so btop underfills the panel until something (a manual resize, a
tab switch) triggers a re-fit. The box size never changes, so a ResizeObserver
alone never fires. Fix: inject a script that polls for ttyd's exposed
window.term, re-fits once available, again after document.fonts.ready and at
short settle intervals, and keeps a ResizeObserver for genuine panel resizes.

ttyd serves gzip when the client accepts it, so the body must be decompressed
before the </head> marker can be found and re-compressed after injection.
"""
import gzip

_RESIZE_FIX = b"""<script>
(function(){
  function fit(){ try{ if(window.term && window.term.fit) window.term.fit(); }catch(e){} }
  var n = 0;
  var iv = setInterval(function(){
    n++;
    var el = document.getElementById('terminal-container');
    if (window.term && window.term.fit && el) {
      clearInterval(iv);
      fit();
      if (window.ResizeObserver) new ResizeObserver(fit).observe(el);
      if (document.fonts && document.fonts.ready) document.fonts.ready.then(function(){ setTimeout(fit, 50); });
      [500, 1500, 3000].forEach(function(ms){ setTimeout(fit, ms); });
    } else if (n > 100) { clearInterval(iv); }
  }, 100);
})();
</script>"""


def rewrite_rmonitor_response(response):
    if "text/html" not in response.headers.get("Content-Type", ""):
        return
    encoding = response.headers.get("Content-Encoding", "").lower()
    body = response.body
    if encoding == "gzip":
        try:
            body = gzip.decompress(body)
        except Exception:
            return
    if b"</head>" not in body:
        return
    body = body.replace(b"</head>", _RESIZE_FIX + b"</head>", 1)
    if encoding == "gzip":
        body = gzip.compress(body)
    response.body = body
    response.headers["Content-Length"] = str(len(body))

# EOF
