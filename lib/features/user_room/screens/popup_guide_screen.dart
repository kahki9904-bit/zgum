import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';

class PopupGuideScreen extends StatefulWidget {
  const PopupGuideScreen({super.key});

  @override
  State<PopupGuideScreen> createState() => _PopupGuideScreenState();
}

class _PopupGuideScreenState extends State<PopupGuideScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('ZGumApp', onMessageReceived: _onMessage)
      ..loadHtmlString(_guideHtml);
  }

  void _onMessage(JavaScriptMessage msg) {
    if (msg.message == 'close' && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.actionGoldText),
        title: const Text(
          'Z:GUM사용방법',
          style: TextStyle(
            color: AppColors.actionGoldText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}

const _guideHtml = '''
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    :root {
      --gold: #b8872f;
      --gold-dark: #76531f;
      --gold-soft: #f8f0df;
      --gold-line: #e0c78c;
      --ink: #2f2f2f;
      --sub: #777777;
      --line: #eeeeee;
      --band: #fafafa;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }

    html, body { height: 100%; overflow: hidden; }

    body {
      background: #fff;
      color: var(--ink);
      font-family: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", sans-serif;
    }

    .layout {
      height: 100vh;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    /* 슬라이드 영역 */
    .viewport {
      flex: 1;
      overflow: hidden;
      min-height: 0;
    }

    .slides {
      display: flex;
      height: 100%;
      transition: transform 340ms ease;
    }

    .slide {
      min-width: 100%;
      height: 100%;
      padding: 16px 18px 12px;
      display: flex;
      flex-direction: column;
      gap: 10px;
      overflow: hidden;
    }

    /* 태그 */
    .kicker {
      display: inline-flex;
      align-items: center;
      height: 24px;
      padding: 0 10px;
      color: var(--gold-dark);
      background: var(--gold-soft);
      border: 1px solid var(--gold-line);
      border-radius: 8px;
      font-size: 11px;
      font-weight: 800;
      flex-shrink: 0;
    }

    /* 메인 카드 */
    .hero {
      padding: 16px 18px 14px;
      background: #fff;
      border: 1px solid var(--line);
      border-radius: 20px;
      box-shadow: 0 6px 18px rgba(0,0,0,0.07);
      flex-shrink: 0;
    }

    h2 {
      color: var(--gold-dark);
      font-size: 21px;
      line-height: 1.2;
      font-weight: 800;
    }

    .lead {
      margin-top: 8px;
      color: var(--ink);
      font-size: 13px;
      line-height: 1.55;
    }

    .support {
      margin-top: 6px;
      color: var(--sub);
      font-size: 12px;
      line-height: 1.5;
    }

    /* 보조 카드 */
    .attached {
      padding: 12px 14px;
      background: var(--band);
      border: 1px solid var(--line);
      border-radius: 14px;
      flex-shrink: 0;
    }

    .attached-title {
      color: var(--gold-dark);
      font-size: 11px;
      font-weight: 800;
    }

    .attached h3 {
      margin-top: 5px;
      color: var(--gold-dark);
      font-size: 15px;
      font-weight: 700;
    }

    .attached p {
      margin-top: 4px;
      color: var(--sub);
      font-size: 12px;
      line-height: 1.5;
    }

    .chips {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin-top: 8px;
    }

    .chip {
      height: 26px;
      display: inline-grid;
      place-items: center;
      padding: 0 9px;
      color: var(--gold-dark);
      background: var(--gold-soft);
      border: 1px solid var(--gold-line);
      border-radius: 8px;
      font-size: 11px;
      font-weight: 800;
    }

    /* choice-box (나의 방 슬라이드) */
    .choice-box {
      margin-top: 8px;
      padding: 10px 12px;
      background: var(--gold-soft);
      border: 1px solid var(--gold-line);
      border-radius: 12px;
    }

    .choice-label {
      color: var(--gold-dark);
      font-size: 11px;
      font-weight: 800;
      line-height: 1.4;
    }

    .choice-text {
      margin-top: 4px;
      color: #5c503e;
      font-size: 11px;
      line-height: 1.5;
    }

    /* 씬 블록 (지도·흐름·그리드) */
    .scene {
      padding: 12px;
      background: var(--band);
      border: 1px solid var(--line);
      border-radius: 14px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    .map {
      width: 100%;
      height: 90px;
      border-radius: 12px;
      background:
        radial-gradient(circle at 24% 30%, rgba(184,135,47,.22) 0 7px, transparent 8px),
        radial-gradient(circle at 68% 42%, rgba(184,135,47,.28) 0 8px, transparent 9px),
        radial-gradient(circle at 50% 72%, rgba(118,83,31,.18) 0 9px, transparent 10px),
        linear-gradient(90deg, transparent 48%, rgba(224,199,140,.42) 49% 51%, transparent 52%),
        linear-gradient(0deg, transparent 46%, rgba(224,199,140,.32) 47% 49%, transparent 50%),
        #fff;
      border: 1px solid #ece4d2;
      position: relative;
    }

    .map::after {
      content: "주변 이벤트";
      position: absolute;
      left: 12px;
      bottom: 10px;
      padding: 5px 9px;
      color: var(--gold-dark);
      background: rgba(255,255,255,.92);
      border: 1px solid var(--gold-line);
      border-radius: 10px;
      font-size: 11px;
      font-weight: 800;
    }

    .flow {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .token {
      height: 42px;
      padding: 0 18px;
      display: grid;
      place-items: center;
      color: var(--gold-dark);
      background: var(--gold-soft);
      border: 1px solid var(--gold-line);
      border-radius: 14px;
      font-size: 14px;
      font-weight: 800;
    }

    .token.fill { color: #fff; background: var(--gold); }

    .arrow { color: var(--gold-dark); font-size: 20px; font-weight: 900; }

    .grid {
      width: 100%;
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 7px;
    }

    .tile {
      aspect-ratio: 1;
      border-radius: 10px;
      background: linear-gradient(135deg, #fbfbfb, #eee6d6);
      border: 1px solid #ececec;
      display: grid;
      place-items: center;
      color: var(--gold-dark);
      font-size: 12px;
      font-weight: 800;
    }

    /* 하단 푸터 */
    footer {
      flex-shrink: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 12px 16px 18px;
      border-top: 1px solid rgba(238,238,238,.8);
      background: #fff;
    }

    .dots {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 6px;
    }

    .dot {
      width: 6px;
      height: 6px;
      border-radius: 999px;
      background: #ddd;
      transition: width 200ms ease, background 200ms ease;
    }

    .dot.active { width: 16px; background: var(--gold); }
  </style>
</head>
<body>
  <div class="layout">
    <div class="viewport">
      <div class="slides" id="slides">

        <article class="slide">
          <span class="kicker">앱 진입</span>
          <div class="hero">
            <h2>지금, 가까운 곳을 봅니다</h2>
            <p class="lead">Z:GUM은 멀리 있는 정보보다 지금 내 주변에서 일어나는 순간을 먼저 보여줍니다.</p>
            <p class="support">지도에서 주변 이벤트를 보고, 필요한 순간에 기록하거나 이어질 수 있습니다.</p>
          </div>
          <div class="scene"><div class="map"></div></div>
        </article>

        <article class="slide">
          <span class="kicker">지도</span>
          <div class="hero">
            <h2>지도에서 둘러보기</h2>
            <p class="lead">앱에 들어오면 중심은 지도입니다. 내 위치 주변의 이벤트와 장소를 한눈에 확인할 수 있습니다.</p>
            <p class="support">검색하거나, 마커를 누르거나, 아래 패널에서 목록을 볼 수 있습니다.</p>
          </div>
          <div class="attached">
            <div class="attached-title">처음 볼 수 있는 안내</div>
            <h3>지도 마커</h3>
            <p>지도 표시를 간단히 구분할 수 있습니다. 선택한 마커는 더 크게 표시됩니다.</p>
            <div class="chips">
              <span class="chip">내 위치</span><span class="chip">내 이벤트</span>
              <span class="chip">등록 이벤트</span><span class="chip">검색 마커</span>
            </div>
          </div>
        </article>

        <article class="slide">
          <span class="kicker">상세</span>
          <div class="hero">
            <h2>마커를 누르면 자세히 볼 수 있습니다</h2>
            <p class="lead">지도 위 마커나 목록의 항목을 누르면 이벤트 정보를 자세히 볼 수 있습니다.</p>
            <p class="support">지금 볼 것, 남길 것, 이동할 것을 빠르게 보여주는 방식입니다.</p>
          </div>
          <div class="scene">
            <div class="flow">
              <span class="token">마커</span>
              <span class="arrow">→</span>
              <span class="token fill">상세</span>
            </div>
          </div>
        </article>

        <article class="slide">
          <span class="kicker">흔적</span>
          <div class="hero">
            <h2>참여한 순간은 나만의 흔적으로 남깁니다</h2>
            <p class="lead">이벤트에 참여한 순간은 사진과 한 줄 메시지로 남길 수 있습니다.</p>
            <p class="support">기록은 나의 방에 쌓이며, 다른 사람에게 공개되지 않습니다.</p>
          </div>
          <div class="attached">
            <div class="attached-title">처음 볼 수 있는 안내</div>
            <h3>지금</h3>
            <p>이벤트에 참여한 순간을 나만의 흔적으로 남길 수 있습니다. 정해진 시간 안에만 가능합니다.</p>
            <div class="chips">
              <span class="chip">남기기</span><span class="chip">확인</span>
              <span class="chip">저장</span><span class="chip">비공개</span>
            </div>
          </div>
        </article>

        <article class="slide">
          <span class="kicker">나의 방</span>
          <div class="hero">
            <h2>나의 방에서 기록을 확인합니다</h2>
            <p class="lead">내가 남긴 흔적과 이어진 사람, 설정은 나의 방에서 확인합니다.</p>
          </div>
          <div class="attached">
            <div class="attached-title">처음 볼 수 있는 안내</div>
            <h3>데이터 안내</h3>
            <p>회원가입이 없는 앱 특성상 앱 삭제·기기 변경 시 기존 데이터를 보존할 수 없습니다.</p>
            <div class="choice-box">
              <div class="choice-label">선택: 이메일을 미리 등록해둘 수 있습니다</div>
              <div class="choice-text">기록을 계속 보관하고 싶다면 앱을 지우거나 기기를 바꾸기 전에 이메일 등록을 해두세요. 이후 데이터 복구에 사용할 수 있습니다.</div>
            </div>
            <div class="chips">
              <span class="chip">설정</span><span class="chip">데이터 복구</span>
            </div>
          </div>
        </article>

        <article class="slide">
          <span class="kicker">이음</span>
          <div class="hero">
            <h2>가까운 사람과 이어질 수 있습니다</h2>
            <p class="lead">같은 공간에 있는 사람과 자연스럽게 이어지는 기능입니다.</p>
            <p class="support">친구가 가까이에 있을 때, 서로 확인한 코드로 연결할 수 있습니다.</p>
          </div>
          <div class="attached">
            <div class="attached-title">처음 볼 수 있는 안내</div>
            <h3>이음</h3>
            <p>지금 곁에 있는 사람과 이어지는 기능입니다. 주변에 친구가 있음을 알려 줍니다.</p>
            <div class="chips">
              <span class="chip">신청</span><span class="chip">수락</span><span class="chip">코드 확인</span>
            </div>
          </div>
        </article>

        <article class="slide">
          <span class="kicker">등록</span>
          <div class="hero">
            <h2>내 이벤트를 주변에 알릴 수 있습니다</h2>
            <p class="lead">가게, 행사, 모임처럼 지금 주변에 알리고 싶은 이벤트가 있다면 등록할 수 있습니다.</p>
            <p class="support">멀리 홍보하는 것보다 가까운 사람에게 지금 보이게 하는 데 초점을 둡니다.</p>
          </div>
          <div class="attached">
            <div class="attached-title">처음 볼 수 있는 안내</div>
            <h3>등록</h3>
            <p>등록한 이벤트는 가까운 사람에게 지금 보이도록 정리됩니다.</p>
            <div class="chips">
              <span class="chip">이곳</span><span class="chip">등록</span>
              <span class="chip">노출</span><span class="chip">기록</span>
            </div>
          </div>
        </article>

        <article class="slide">
          <span class="kicker">사진</span>
          <div class="hero">
            <h2>카메라는 원하는 방식으로 사용합니다</h2>
            <p class="lead">흔적을 남길 때 카메라를 사용할 수 있습니다.</p>
            <p class="support">기기 설정에 따라 기본 카메라 앱이 바로 열릴 수 있습니다.</p>
          </div>
          <div class="attached">
            <div class="attached-title">처음 볼 수 있는 안내</div>
            <h3>카메라 안내</h3>
            <p>기기 설정에서 카메라 기본값을 해제하면 원하는 앱으로 찍을 수 있습니다.</p>
            <p>Z:GUM의 기록은 지금 이 자리에서 찍은 사진으로 남겨집니다. 지난 사진보다 현재의 순간을 담는 데 집중합니다.</p>
          </div>
        </article>

        <article class="slide">
          <span class="kicker">방향</span>
          <div class="hero">
            <h2>가까운 순간을 작게, 오래</h2>
            <p class="lead">Z:GUM은 거대한 피드보다 지금 내 주변의 작은 순간을 놓치지 않게 돕는 앱입니다.</p>
            <p class="support">지도에서 발견하고, 참여하고, 남기고, 필요하면 이어집니다.</p>
          </div>
          <div class="scene">
            <div class="grid">
              <div class="tile">발견</div><div class="tile">참여</div><div class="tile">기록</div>
              <div class="tile">이음</div><div class="tile">등록</div><div class="tile">지금</div>
            </div>
          </div>
        </article>

      </div>
    </div>

    <footer>
      <div class="dots" id="dots"></div>
    </footer>
  </div>

  <script>
    const viewport = document.querySelector('.viewport');
    const slides = document.getElementById('slides');
    const dots = document.getElementById('dots');
    const total = slides.children.length;
    let index = 0;
    let startX = null;
    let startY = null;
    let isHorizontal = null;

    for (let i = 0; i < total; i++) {
      const dot = document.createElement('span');
      dot.className = 'dot';
      dots.appendChild(dot);
    }

    function render() {
      const w = viewport.offsetWidth;
      slides.style.transform = 'translateX(' + (-index * w) + 'px)';
      [...dots.children].forEach((d, i) => d.classList.toggle('active', i === index));
    }

    viewport.addEventListener('touchstart', e => {
      startX = e.touches[0].clientX;
      startY = e.touches[0].clientY;
      isHorizontal = null;
    }, { passive: true });

    viewport.addEventListener('touchmove', e => {
      if (startX === null || isHorizontal !== null) return;
      const dx = Math.abs(e.touches[0].clientX - startX);
      const dy = Math.abs(e.touches[0].clientY - startY);
      isHorizontal = dx > dy;
    }, { passive: true });

    viewport.addEventListener('touchend', e => {
      if (startX === null || !isHorizontal) { startX = null; return; }
      const dx = e.changedTouches[0].clientX - startX;
      if (dx < -40 && index < total - 1) index++;
      else if (dx > 40 && index > 0) index--;
      startX = null;
      render();
    }, { passive: true });

    render();
  </script>
</body>
</html>
''';
