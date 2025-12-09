// 前端流程占位实现：开始界面 -> 选择模式（随机/普通）-> 后续动作。
// 需要后端提供 chart_engine / chart_analysis 接口。

const state = {
  started: false,
  mode: null,
  charts: [],
  selectedChart: null,
  randomReady: false,
};

const BASE_PATH = detectBasePath();
const PROTOCOL_URL = `${BASE_PATH}chart_analysis/outputs/protocol.json`;

// 模拟数据：仅用于 UI 占位，实际应从 chart_analysis 拉取（排除 Random 目录）。
const MOCK_CHARTS = [
  { id: "Cthugha", name: "Cthugha", bpm: 170, duration: "02:10", folder: "charts/Cthugha" },
  { id: "Cthugha_1", name: "Cthugha_1", bpm: 170, duration: "02:10", folder: "charts/Cthugha_1" },
  { id: "Cthugha_2", name: "Cthugha_2", bpm: 170, duration: "02:10", folder: "charts/Cthugha_2" },
  { id: "Cthugha_3", name: "Cthugha_3", bpm: 170, duration: "02:10", folder: "charts/Cthugha_3" },
  { id: "Random", name: "Random", bpm: 170, duration: "02:10", folder: "charts/Random" },
];

const els = {
  overlay: document.getElementById("startOverlay"),
  modeBar: document.getElementById("modeBar"),
  normalPanel: document.getElementById("normalPanel"),
  randomPanel: document.getElementById("randomPanel"),
  normalStatus: document.getElementById("normalStatus"),
  randomStatus: document.getElementById("randomStatus"),
  trackList: document.getElementById("trackList"),
  previewMeta: document.getElementById("previewMeta"),
  previewImages: document.getElementById("previewImages"),
  previewData: document.getElementById("previewData"),
  normalActions: document.getElementById("normalActions"),
  toast: document.getElementById("toast"),
  btnSelectNormal: document.getElementById("btn-select-normal"),
  btnOpenQuartus: document.getElementById("btn-open-quartus"),
  btnModeRandom: document.getElementById("btn-mode-random"),
  btnModeNormal: document.getElementById("btn-mode-normal"),
  btnGenerateRandom: document.getElementById("btn-generate-random"),
  btnStartRandom: document.getElementById("btn-start-random"),
  randomPreview: document.getElementById("randomPreview"),
  randomData: document.getElementById("randomData"),
};

// 单一音频预览实例
const previewAudio = new Audio();
previewAudio.loop = false;
let fadeTimer = null;
let fadeOutScheduled = false;

function showToast(message) {
  if (!els.toast) return;
  els.toast.textContent = message;
  els.toast.classList.add("show");
  setTimeout(() => els.toast.classList.remove("show"), 2200);
}

function startExperience() {
  if (state.started) return;
  state.started = true;
  if (els.overlay) els.overlay.classList.add("hidden");
  if (els.modeBar) els.modeBar.classList.remove("hidden");
  showToast("选择模式开始吧！");
}

function switchMode(mode) {
  state.mode = mode;
  if (mode === "normal") {
    if (els.normalPanel) els.normalPanel.classList.remove("hidden");
    if (els.randomPanel) els.randomPanel.classList.add("hidden");
    runAnalysisAndLoadCharts();
  } else if (mode === "random") {
    if (els.randomPanel) els.randomPanel.classList.remove("hidden");
    if (els.normalPanel) els.normalPanel.classList.add("hidden");
    state.randomReady = false;
    if (els.btnStartRandom) els.btnStartRandom.disabled = true;
    if (els.randomStatus) els.randomStatus.textContent = "等待生成 Random 谱面...";
    if (els.randomPreview) els.randomPreview.innerHTML = "";
    if (els.randomData) els.randomData.textContent = "等待 chart_analysis 输出 summary JSON";
  }
}

async function runAnalysisAndLoadCharts() {
  if (els.normalStatus) els.normalStatus.textContent = "调用 chart_analysis 解析所有谱面...";
  try {
    await triggerAnalysisForAllCharts();
    await loadCharts();
  } catch (err) {
    console.error(err);
    if (els.normalStatus) els.normalStatus.textContent = "解析或加载失败，请检查后台服务。";
  }
}

async function loadCharts() {
  if (els.normalStatus) els.normalStatus.textContent = "加载谱面中...";
  try {
    const charts = await fetchChartsFromBackend();
    // 普通模式不显示 Random
    state.charts = charts.filter((c) => c.name !== "Random");
    renderTrackList(state.charts);
    if (els.normalStatus) {
      els.normalStatus.textContent = charts.length ? "悬停预览，点击选中。" : "未找到谱面，请检查 charts 目录。";
    }
  } catch (err) {
    console.error(err);
    if (els.normalStatus) els.normalStatus.textContent = "加载失败，请检查后台服务。";
  }
}

async function fetchChartsFromBackend() {
  try {
    const res = await fetch(PROTOCOL_URL);
    if (!res.ok) throw new Error(`protocol fetch failed: ${res.status}`);
    const protocol = await res.json();
    if (!protocol.charts || !Array.isArray(protocol.charts)) throw new Error("protocol missing charts array");
    return protocol.charts.map((c) => ({
      id: c.name,
      name: c.name,
      bpm: c.bpm || "?",
      duration: c.duration || "--:--",
      folder: c.folder || `charts/${c.name}`,
      analysisImages: (c.files || []).map((f) => `${BASE_PATH}chart_analysis/outputs/${f}`),
      analysisSummary: c.summary ? `${BASE_PATH}chart_analysis/outputs/${c.summary}` : null,
      audio: c.audio ? `${BASE_PATH}${c.audio}` : `${BASE_PATH}${c.folder || `charts/${c.name}`}/${c.name}.mp3`,
    }));
  } catch (err) {
    console.warn("protocol load failed, fallback to mock", err);
    return MOCK_CHARTS.map((c) => ({
      ...c,
      analysisImages: [`${BASE_PATH}chart_analysis/outputs/${c.name}_dummy.png`],
      analysisSummary: `${BASE_PATH}chart_analysis/outputs/${c.name}_summary.json`,
      audio: `${BASE_PATH}${c.folder}/${c.name}.mp3`,
    }));
  }
}

function triggerAnalysisForAllCharts() {
  // 占位：实际应调用 chart_analysis 的“解析全部谱面”接口。
  return Promise.resolve();
}

function renderTrackList(charts) {
  if (!els.trackList) return;
  els.trackList.innerHTML = "";
  if (!charts.length) return;
  charts.forEach((chart) => {
    const card = document.createElement("div");
    card.className = "track-card";
    card.dataset.id = chart.id;
    card.innerHTML = `
      <div class="track-name">${chart.name}</div>
      <div class="track-meta">BPM: ${chart.bpm || "?"} · 时长: ${chart.duration || "--:--"}</div>
      <div class="track-meta">目录: ${chart.folder || "charts/??"}</div>
      <div class="track-meta" style="margin-top:6px;">点击选中 / 悬停放大</div>
    `;
    card.addEventListener("mouseenter", () => handleHover(chart));
    card.addEventListener("mouseleave", stopPreviewAudio);
    card.addEventListener("click", () => selectChart(chart, card));
    els.trackList.appendChild(card);
  });
}

function handleHover(chart) {
  if (els.previewMeta) els.previewMeta.textContent = `预览：${chart.name} （自动播放音频并展示分析图，需后台支持）`;
  renderPreviewImages(chart.analysisImages, els.previewImages);
  renderSummary(chart.analysisSummary, els.previewData);
  playPreviewAudio(chart);
}

function renderPreviewImages(images, target) {
  if (!target) return;
  target.innerHTML = "";
  if (!images || !images.length) {
    const placeholder = document.createElement("div");
    placeholder.className = "placeholder-box";
    placeholder.textContent = "等待 chart_analysis 输出分析图";
    target.appendChild(placeholder);
    return;
  }
  images.forEach((src) => {
    const img = document.createElement("img");
    img.src = src;
    img.alt = "chart analysis";
    target.appendChild(img);
  });
}

async function renderSummary(summaryPath, target) {
  if (!target) return;
  if (!summaryPath) {
    target.textContent = "等待 chart_analysis 输出 summary JSON";
    return;
  }
  target.textContent = "加载分析数据...";
  try {
    const res = await fetch(summaryPath);
    if (!res.ok) throw new Error(`fetch failed: ${res.status}`);
    const data = await res.json();
    target.textContent = formatSummary(data);
  } catch (err) {
    console.warn("summary load failed", err);
    target.textContent = "未找到 summary JSON（请检查 chart_analysis 输出路径）";
  }
}

function formatSummary(data) {
  if (!data || typeof data !== "object") return "无有效数据";
  const lines = [];
  if (data.title) lines.push(`曲目: ${data.title}`);
  if (data.duration) lines.push(`时长: ${data.duration}`);
  if (data.bpm) lines.push(`BPM: ${data.bpm}`);
  if (data.note_count) lines.push(`音符数量: ${data.note_count}`);
  if (data.density_peak) lines.push(`密度峰值: ${data.density_peak}`);
  if (data.density_avg) lines.push(`平均密度: ${data.density_avg}`);
  if (data.note_types) lines.push(`音符类型: ${JSON.stringify(data.note_types)}`);
  if (lines.length === 0) lines.push(JSON.stringify(data, null, 2));
  return lines.join("\n");
}

function selectChart(chart, cardEl) {
  state.selectedChart = chart;
  document.querySelectorAll(".track-card").forEach((c) => c.classList.remove("selected"));
  if (cardEl) cardEl.classList.add("selected");
  if (els.normalActions) els.normalActions.style.display = "flex";
  if (els.previewMeta) els.previewMeta.textContent = `已选中：${chart.name} · 点击下方按钮写入 BPM & ROM 或打开 Quartus。`;
}

async function applyNormalSelection() {
  if (!state.selectedChart) {
    showToast("请先选中曲目");
    return;
  }
  const name = state.selectedChart.name;
  if (els.normalStatus) els.normalStatus.textContent = `调用 chart_engine 处理中：${name}...`;
  const ok = await runChartEngine(name);
  if (ok) {
    showToast(`写入成功：${name}`);
    if (els.normalStatus) els.normalStatus.textContent = `写入成功：${name}`;
  } else {
    showToast(`写入失败：${name}`);
    if (els.normalStatus) els.normalStatus.textContent = `写入失败：${name}`;
  }
}

async function runChartEngine(chartName) {
  const url = `${BASE_PATH}chart_engine/process?name=${encodeURIComponent(chartName)}`;
  try {
    const res = await fetch(url, { method: "POST" });
    if (!res.ok) throw new Error(`process failed: ${res.status}`);
    const data = await res.json().catch(() => ({}));
    return data.success === true;
  } catch (err) {
    console.warn("runChartEngine failed", err);
    return false;
  }
}

function openQuartus() {
  showToast("打开 Quartus：quartus/MuseDash.qsf");
}

function generateRandomChart() {
  if (els.randomStatus) els.randomStatus.textContent = "生成中（调用 chart_engine Random）...";
  if (els.btnStartRandom) els.btnStartRandom.disabled = true;
  if (els.randomPreview) els.randomPreview.innerHTML = "";
  if (els.randomData) els.randomData.textContent = "等待 chart_analysis 输出 summary JSON";
  (async () => {
    const ok = await runGenerateRandom();
    state.randomReady = true;
    if (els.btnStartRandom) els.btnStartRandom.disabled = false;
    if (els.randomStatus) els.randomStatus.textContent = ok ? "生成完成，点击开始或重新生成。" : "生成失败，仍可尝试开始或重试生成。";
    await loadRandomPreview();
    showToast(ok ? "Random 谱面生成完成" : "Random 谱面生成失败（占位）");
  })();
}

function startRandomBuild() {
  if (!state.randomReady) {
    showToast("请先生成 Random 谱面");
    return;
  }
  showToast("Random 模式：已请求写入并启动");
}

async function runGenerateRandom() {
  const url = `${BASE_PATH}chart_engine/generate_random`;
  try {
    const res = await fetch(url, { method: "POST" });
    if (!res.ok) throw new Error(`generate_random failed: ${res.status}`);
    const data = await res.json().catch(() => ({}));
    return data.success === true;
  } catch (err) {
    console.warn("runGenerateRandom failed", err);
    return false;
  }
}

async function loadRandomPreview() {
  try {
    const res = await fetch(PROTOCOL_URL);
    if (!res.ok) throw new Error(`protocol fetch failed: ${res.status}`);
    const protocol = await res.json();
    const entry = protocol.charts?.find((c) => c.name === "Random");
    if (!entry) throw new Error("no Random entry in protocol");
    renderPreviewImages((entry.files || []).map((f) => `${BASE_PATH}chart_analysis/outputs/${f}`), els.randomPreview);
    renderSummary(entry.summary ? `${BASE_PATH}chart_analysis/outputs/${entry.summary}` : null, els.randomData);
    return;
  } catch (err) {
    console.warn("loadRandomPreview failed", err);
    renderPreviewImages([`${BASE_PATH}chart_analysis/outputs/Random_dummy.png`], els.randomPreview);
    if (els.randomData) {
      els.randomData.textContent = "占位 summary：请检查 chart_analysis/outputs/Random_summary.json 是否可访问。";
    }
  }
}

function bindEvents() {
  if (els.overlay) els.overlay.addEventListener("click", startExperience);
  if (els.btnModeNormal) els.btnModeNormal.addEventListener("click", () => switchMode("normal"));
  if (els.btnModeRandom) els.btnModeRandom.addEventListener("click", () => switchMode("random"));
  if (els.btnSelectNormal) els.btnSelectNormal.addEventListener("click", applyNormalSelection);
  if (els.btnOpenQuartus) els.btnOpenQuartus.addEventListener("click", openQuartus);
  if (els.btnGenerateRandom) els.btnGenerateRandom.addEventListener("click", generateRandomChart);
  if (els.btnStartRandom) els.btnStartRandom.addEventListener("click", startRandomBuild);
}

function init() {
  bindEvents();
  renderPreviewImages([], els.previewImages);
  renderSummary(null, els.previewData);
  renderPreviewImages([], els.randomPreview);
  renderSummary(null, els.randomData);
}

init();

function detectBasePath() {
  const loc = window.location;
  const pathname = loc.pathname.replace(/\\/g, "/");
  const parts = pathname.split("/");
  const idx = parts.lastIndexOf("frontend");
  let base = "/";
  if (idx > 0) {
    base = parts.slice(0, idx).join("/") + "/";
  }
  if (loc.origin && loc.origin !== "null") {
    return `${loc.origin}${base}`;
  }
  return `file://${base}`;
}

function playPreviewAudio(chart) {
  const src = chart.audio || `${BASE_PATH}${chart.folder}/${chart.name}.mp3`;
  if (!src) return;

  clearInterval(fadeTimer);
  fadeOutScheduled = false;
  previewAudio.pause();
  previewAudio.src = src;
  previewAudio.volume = 0;
  previewAudio.onloadedmetadata = () => {
    const duration = previewAudio.duration || 0;
    const maxStart = Math.max(0, duration - 30);
    const start = Math.random() * (maxStart > 0 ? maxStart : 0);
    previewAudio.currentTime = start;
    fadeIn(previewAudio, 1.5);
    previewAudio.play().catch((err) => console.warn("audio play blocked", err));
  };

  previewAudio.ontimeupdate = () => {
    const remaining = (previewAudio.duration || 0) - previewAudio.currentTime;
    if (!fadeOutScheduled && remaining > 0 && remaining <= 1.5) {
      fadeOutScheduled = true;
      fadeOutAndRestart(previewAudio, 1.2);
    }
  };
}

function stopPreviewAudio() {
  clearInterval(fadeTimer);
  fadeOutScheduled = false;
  previewAudio.pause();
}

function fadeIn(audio, durationSec) {
  const steps = 20;
  const stepTime = (durationSec * 1000) / steps;
  let vol = 0;
  audio.volume = 0;
  clearInterval(fadeTimer);
  fadeTimer = setInterval(() => {
    vol += 1 / steps;
    audio.volume = Math.min(1, vol);
    if (vol >= 1) clearInterval(fadeTimer);
  }, stepTime);
}

function fadeOutAndRestart(audio, durationSec) {
  const steps = 20;
  const stepTime = (durationSec * 1000) / steps;
  let vol = audio.volume;
  clearInterval(fadeTimer);
  fadeTimer = setInterval(() => {
    vol -= 1 / steps;
    audio.volume = Math.max(0, vol);
    if (vol <= 0) {
      clearInterval(fadeTimer);
      restartRandomSegment(audio);
    }
  }, stepTime);
}

function restartRandomSegment(audio) {
  const duration = audio.duration || 0;
  const maxStart = Math.max(0, duration - 30);
  const start = Math.random() * (maxStart > 0 ? maxStart : 0);
  fadeOutScheduled = false;
  audio.currentTime = start;
  fadeIn(audio, 1.2);
  audio.play().catch((err) => console.warn("audio replay blocked", err));
}
