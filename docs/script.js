document.querySelectorAll('a[href^="#"]').forEach(function (link) {
  link.addEventListener("click", function (e) {
    var target = document.querySelector(link.getAttribute("href"));
    if (target) {
      e.preventDefault();
      target.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  });
});

document.querySelectorAll(".copy-btn").forEach(function (btn) {
  btn.addEventListener("click", function () {
    var block = btn.closest(".codeblock");
    if (!block) return;
    var code = block.querySelector("code");
    if (!code) return;
    var text = code.textContent;

    function success() {
      btn.textContent = "Copied";
      btn.classList.add("copied");
      setTimeout(function () {
        btn.textContent = "Copy";
        btn.classList.remove("copied");
      }, 1600);
    }

    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(success).catch(fallbackCopy);
    } else {
      fallbackCopy();
    }

    function fallbackCopy() {
      var ta = document.createElement("textarea");
      ta.value = text;
      ta.style.position = "fixed";
      ta.style.top = "-9999px";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.focus();
      ta.select();
      try {
        document.execCommand("copy");
        success();
      } catch (err) {}
      document.body.removeChild(ta);
    }
  });
});

var sections = document.querySelectorAll("section[id]");
var navLinks = document.querySelectorAll(".nav-link");

if (sections.length && navLinks.length && "IntersectionObserver" in window) {
  var navObserver = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          var id = entry.target.id;
          navLinks.forEach(function (link) {
            link.classList.toggle("active", link.getAttribute("href") === "#" + id);
          });
        }
      });
    },
    { rootMargin: "-88px 0px -70% 0px", threshold: 0 }
  );
  sections.forEach(function (s) { navObserver.observe(s); });
}

document.querySelectorAll(".section").forEach(function (s) {
  s.classList.add("animate-in");
});

if ("IntersectionObserver" in window) {
  var revealObserver = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("visible");
          revealObserver.unobserve(entry.target);
        }
      });
    },
    { rootMargin: "0px 0px -50px 0px", threshold: 0 }
  );
  document.querySelectorAll(".section").forEach(function (s) {
    revealObserver.observe(s);
  });
} else {
  document.querySelectorAll(".section").forEach(function (s) {
    s.classList.add("visible");
  });
}

var mock = document.querySelector('.hero-mock');
var windowMock = document.querySelector('.mock-window');

if (mock && windowMock && window.innerWidth > 1100) {
  mock.addEventListener('mousemove', function(e) {
    if (windowMock.classList.contains('closed') || windowMock.classList.contains('minimized')) return;
    var rect = mock.getBoundingClientRect();
    var x = e.clientX - rect.left;
    var y = e.clientY - rect.top;
    
    var centerX = rect.width / 2;
    var centerY = rect.height / 2;
    
    var rotateY = ((x - centerX) / centerX) * 12;
    var rotateX = -((y - centerY) / centerY) * 12;
    
    windowMock.style.transform = `rotateY(${rotateY}deg) rotateX(${rotateX}deg) scale(1.02)`;
  });
  
  mock.addEventListener('mouseleave', function() {
    windowMock.style.transform = 'rotateY(-8deg) rotateX(4deg) scale(0.95)';
  });
}

document.addEventListener("DOMContentLoaded", function() {
  var mockTabs = document.querySelectorAll(".mock-tab");
  var mockPages = document.querySelectorAll(".mock-page");
  
  mockTabs.forEach(function(tab) {
    tab.addEventListener("click", function() {
      mockTabs.forEach(function(t) { t.classList.remove("active"); });
      mockPages.forEach(function(p) { p.classList.remove("active"); p.style.display = "none"; });
      
      tab.classList.add("active");
      var targetId = tab.getAttribute("data-target");
      var targetPage = document.getElementById(targetId);
      if (targetPage) {
        targetPage.style.display = "flex";
        setTimeout(function() { targetPage.classList.add("active"); }, 10);
      }
    });
  });

  document.querySelectorAll(".mock-toggle").forEach(function(toggle) {
    toggle.addEventListener("click", function() {
      toggle.classList.toggle("on");
    });
  });

  var slider = document.getElementById("mockSlider");
  var sliderFill = document.getElementById("mockSliderFill");
  var sliderThumb = document.getElementById("mockSliderThumb");
  var sliderVal = document.getElementById("mockSliderVal");
  var isDragging = false;

  function updateSlider(e) {
    if (!isDragging) return;
    var rect = slider.getBoundingClientRect();
    var x = Math.max(0, Math.min(e.clientX - rect.left, rect.width));
    var percent = x / rect.width;
    
    sliderFill.style.width = (percent * 100) + "%";
    sliderThumb.style.left = (percent * 100) + "%";
    if (sliderVal) {
      sliderVal.textContent = Math.round(percent * 5000) + "m";
    }
  }

  if (slider) {
    slider.addEventListener("pointerdown", function(e) {
      isDragging = true;
      updateSlider(e);
      slider.setPointerCapture(e.pointerId);
    });
    slider.addEventListener("pointermove", updateSlider);
    slider.addEventListener("pointerup", function() { isDragging = false; });
  }

  var minBtn = document.getElementById("mockMinBtn");
  var closeBtn = document.getElementById("mockCloseBtn");
  var reopenBtn = document.getElementById("mockReopen");

  if (minBtn) {
    minBtn.addEventListener("click", function() {
      windowMock.classList.toggle("minimized");
    });
  }

  if (closeBtn) {
    closeBtn.addEventListener("click", function() {
      windowMock.classList.add("closed");
      reopenBtn.classList.add("show");
    });
  }

  if (reopenBtn) {
    reopenBtn.addEventListener("click", function() {
      reopenBtn.classList.remove("show");
      windowMock.classList.remove("closed");
      windowMock.classList.remove("minimized");
    });
  }
});
