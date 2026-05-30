(function () {
  var nav = document.querySelector("[data-site-nav]");
  if (!nav) return;

  var inLegal = nav.getAttribute("data-site-nav") === "legal";
  var legalPrefix = inLegal ? "" : "legal/";
  var homeHref = inLegal ? "../index.html" : "index.html";
  var current = "home";
  if (location.pathname.indexOf("/legal/") !== -1) {
    current = location.pathname.split("/").pop().replace(/\.html$/, "");
  }

  var items = [
    { id: "home", label: "ホーム", href: homeHref },
    { id: "tokushoho", label: "特商法表記", href: legalPrefix + "tokushoho.html" },
    { id: "terms", label: "利用規約", href: legalPrefix + "terms.html" },
    { id: "privacy", label: "プライバシー", href: legalPrefix + "privacy.html" },
    { id: "subscription", label: "サブスク", href: legalPrefix + "subscription.html" },
    { id: "contact", label: "お問い合わせ", href: "mailto:seirogan888@gmail.com" }
  ];

  nav.innerHTML = items
    .map(function (item) {
      var isActive = item.id === current;
      var attrs = isActive ? ' aria-current="page" class="is-active"' : "";
      return '<a href="' + item.href + '"' + attrs + ">" + item.label + "</a>";
    })
    .join("");
})();
