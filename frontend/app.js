// 前端流程占位实现：开始界面 -> 选择模式（随机/普通）-> 后续动作
// 需要后端提供 chart_engine / chart_analysis 接口

const state = {
  started: false,
  mode: null,
  charts: [],
  selectedChart: null,
  randomReady: false,
  randomGenerated: false,
};

const BASE_PATH = detectBasePath();
const PROTOCOL_URL = `${BASE_PATH}chart_analysis/outputs/protocol.json`;
const ANALYSIS_ENDPOINT = `${BASE_PATH}chart_analysis/run`;
const RANDOM_COVER = `${BASE_PATH}charts/Random/Random.png`;
let chartAnalysisPromise = null;

// 假设谱面时间以 tick 计，当前按 4 tick = 1 拍 进行换算
const TICKS_PER_BEAT = 4;

// 模拟数据：仅用于 UI 占位，实际应从 chart_analysis 拉取（排除 Random 目录）
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
  modeChooser: document.getElementById("modeChooser"),
  btnChooseRandom: document.getElementById("btn-choose-random"),
  btnChooseNormal: document.getElementById("btn-choose-normal"),
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
  btnPlayNormal: document.getElementById("btn-play-normal"),
  btnModeRandom: document.getElementById("btn-mode-random"),
  btnModeNormal: document.getElementById("btn-mode-normal"),
  btnGenerateRandom: document.getElementById("btn-generate-random"),
  btnSelectRandom: document.getElementById("btn-select-random"),
  btnOpenRandom: document.getElementById("btn-open-random"),
  btnPlayRandom: document.getElementById("btn-play-random"),
  randomPreview: document.getElementById("randomPreview"),
  randomData: document.getElementById("randomData"),
  randomMeta: document.getElementById("randomMeta"),
  randomCardImage: document.getElementById("randomCardImage"),
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
  if (els.modeChooser) els.modeChooser.classList.remove("hidden");
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
    // 仅首次进入随机模式时自动生成
    if (!state.randomGenerated) {
      state.randomReady = false;
      if (els.randomStatus) els.randomStatus.textContent = "等待生成 Random 谱面...";
      if (els.randomMeta) els.randomMeta.textContent = "BPM: -- · 时长: --:--";
      if (els.randomCardImage) els.randomCardImage.src = "";
      if (els.randomPreview) els.randomPreview.innerHTML = "";
      if (els.randomData) els.randomData.textContent = "等待 chart_analysis 输出 summary JSON";
      generateRandomChart(true);
    }
  }
}

async function runAnalysisAndLoadCharts() {
  if (els.normalStatus) els.normalStatus.textContent = "调用 chart_analysis 解析所有谱面...";
  console.log("[frontend] normal mode -> trigger chart_analysis");
  try {
    await triggerAnalysisForAllCharts();
    await loadCharts();
    if (els.normalStatus) els.normalStatus.textContent = "解析完成";
  } catch (err) {
    console.error(err);
    if (els.normalStatus) els.normalStatus.textContent = "解析或加载失败，请检查后台服务";
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
      els.normalStatus.textContent = charts.length ? "悬停预览，点击选中" : "未找到谱面，请检查 charts 目录";
    }
  } catch (err) {
    console.error(err);
    if (els.normalStatus) els.normalStatus.textContent = "加载失败，请检查后台服务";
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
      folder: ensureChartsFolder(c.folder, c.name),
      analysisImages: (c.files || []).map((f) => `${BASE_PATH}chart_analysis/outputs/${f}`),
      analysisSummary: c.summary ? `${BASE_PATH}chart_analysis/outputs/${c.summary}` : null,
      audio: normalizeAudioPath(c),
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
  return triggerChartAnalysisRun();
}

function triggerChartAnalysisRun(statusEl = els.normalStatus) {
  if (chartAnalysisPromise) {
    return chartAnalysisPromise;
  }
  if (statusEl) {
    statusEl.textContent = "请求 chart_analysis 运行...";
  }
  console.log("[frontend] POST", ANALYSIS_ENDPOINT);
  chartAnalysisPromise = (async () => {
    try {
      const res = await fetch(ANALYSIS_ENDPOINT, { method: "POST" });
      if (!res.ok) {
        throw new Error(`chart_analysis run failed: ${res.status}`);
      }
      const data = await res.json().catch(() => ({}));
      if (data.success !== true) {
        throw new Error(data.message || "chart_analysis 返回失败");
      }
      console.log("[frontend] chart_analysis success", data.message || "");
      if (statusEl) {
        statusEl.textContent = "chart_analysis 完成，准备加载协议文件...";
      }
      return true;
    } catch (err) {
      console.warn("chart_analysis request failed", err);
      if (statusEl) {
        statusEl.textContent = "chart_analysis 调用失败，请检查后台服务";
      }
      if (els.toast) {
        showToast("chart_analysis 调用失败，请查看后台日志");
      }
      throw err;
    } finally {
      chartAnalysisPromise = null;
    }
  })();
  return chartAnalysisPromise;
}

function renderTrackList(charts) {
  if (!els.trackList) return;
  els.trackList.innerHTML = "";
  if (!charts.length) return;
  charts.forEach((chart) => {
    const card = document.createElement("div");
    card.className = "track-card";
    card.dataset.id = chart.id;

    const content = document.createElement("div");
    content.className = "track-content";

    const info = document.createElement("div");
    info.className = "track-info";
    info.innerHTML = `
      <div class="track-name">${chart.name}</div>
      <div class="track-meta">BPM: ${chart.bpm || "?"} · 时长: ${formatDurationForDisplay(chart.duration_raw || chart.duration, chart.bpm)}</div>
      <div class="track-meta">目录: ${ensureChartsFolder(chart.folder, chart.name)}</div>
    `;

    const images = document.createElement("div");
    images.className = "track-images";
    const cover = buildCoverImage(chart);
    if (cover) {
      const img = document.createElement("img");
      img.src = cover;
      img.alt = `${chart.name} cover`;
      images.appendChild(img);
    } else {
      const placeholder = document.createElement("div");
      placeholder.className = "track-image-placeholder";
      placeholder.textContent = "暂无封面";
      images.appendChild(placeholder);
    }

    content.appendChild(info);
    content.appendChild(images);
    card.appendChild(content);

    card.addEventListener("mouseenter", () => handleHover(chart));
    card.addEventListener("mouseleave", stopPreviewAudio);
    card.addEventListener("click", () => selectChart(chart, card));
    els.trackList.appendChild(card);
  });
}

function handleHover(chart) {
  if (els.previewMeta) els.previewMeta.textContent = "谱面信息统计：";
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
  const durationStr = formatDurationForDisplay(data.duration, data.bpm);
  if (durationStr) lines.push(`时长: ${durationStr}`);
  if (data.bpm) lines.push(`BPM: ${data.bpm}`);
  if (data.note_count) lines.push(`音符数量: ${data.note_count}`);
  const peakPerSec = toNotesPerSecond(data.density_peak, data.duration, data.bpm);
  if (peakPerSec) lines.push(`密度峰值: ${peakPerSec} 物量/秒`);
  const avgPerSec = toNotesPerSecond(data.density_avg, data.duration, data.bpm, true);
  if (avgPerSec) lines.push(`平均密度: ${avgPerSec} 物量/秒`);
  if (data.note_types) lines.push(`物量: ${formatNoteTypes(data.note_types)}`);
  if (lines.length === 0) lines.push(JSON.stringify(data, null, 2));
  return lines.join("\n");
}

function formatDurationForDisplay(duration, bpm) {
  if (typeof duration !== "number" || duration <= 0) return "";
  if (typeof bpm !== "number" || bpm <= 0) {
    // 没有 BPM 就直接返回原值
    return `${duration}`;
  }
  // tick -> 秒：tick / TICKS_PER_BEAT 拍，拍 -> 秒：(拍 / BPM) * 60
  const seconds = (duration / TICKS_PER_BEAT) * (60 / bpm);
  const m = Math.floor(seconds / 60);
  const s = Math.round(seconds % 60);
  const mm = String(m).padStart(2, "0");
  const ss = String(s).padStart(2, "0");
  return `${mm}分${ss}秒`;
}

function toNotesPerSecond(val, duration, bpm, isAvg = false) {
  if (typeof val !== "number" || val <= 0) return "";
  if (typeof bpm !== "number" || bpm <= 0) return `${val}`;
  if (typeof duration !== "number" || duration <= 0) return `${val}`;
  // 与 chart_analysis 相同的窗口大小：max(100, duration // 100)
  const windowSize = Math.max(100, Math.floor(duration / 100));
  const secondsPerTick = (60 / bpm) / TICKS_PER_BEAT;
  const windowSeconds = windowSize * secondsPerTick;
  if (windowSeconds <= 0) return `${val}`;
  const perSec = val / windowSeconds;
  const rounded = Math.round(perSec * 100) / 100;
  return rounded.toFixed(2);
}

function formatNoteTypes(noteTypes) {
  if (!noteTypes || typeof noteTypes !== "object") return "";
  const labelMap = {
    tap: "单击",
    hold_start: "长条头",
    hold_mid: "长条中段",
    hold_end: "长按结束",
  };
  const parts = [];
  for (const [k, v] of Object.entries(noteTypes)) {
    const label = labelMap[k] || k;
    parts.push(`${v} ${label}`);
  }
  return parts.join("，");
}

function normalizeAudioPath(c) {
  let folderPath = ensureChartsFolder(c.folder, c.name);
  let audioRel = c.audio;
  if (!audioRel) {
    audioRel = `${folderPath}/${c.name}.mp3`;
  } else if (!audioRel.includes("/")) {
    // 如果协议里只有文件名，自动补上目录
    audioRel = `${folderPath}/${audioRel}`;
  } else if (audioRel.startsWith("./")) {
    audioRel = `${folderPath}/${audioRel.replace(/^\.\//, "")}`;
  }
  if (audioRel.startsWith("http://") || audioRel.startsWith("https://")) {
    return audioRel;
  }
  return `${BASE_PATH}${audioRel.replace(/^\/+/, "")}`;
}

function ensureChartsFolder(folder, name) {
  let folderPath = folder || `charts/${name}`;
  folderPath = folderPath.replace(/^\/+/, "");
  if (!folderPath.startsWith("charts/")) {
    folderPath = `charts/${folderPath}`;
  }
  return folderPath;
}

function buildCoverImage(chart) {
  const folderPath = ensureChartsFolder(chart.folder, chart.name);
  return `${BASE_PATH}${folderPath}/${chart.name}.png`;
}

function selectChart(chart, cardEl) {
  state.selectedChart = chart;
  document.querySelectorAll(".track-card").forEach((c) => c.classList.remove("selected"));
  if (cardEl) cardEl.classList.add("selected");
  if (els.previewMeta) els.previewMeta.textContent = `已选中：${chart.name} · 点击下方按钮写入 BPM & ROM 或打开 Quartus`;
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
  const qsfPath = "quartus/MuseDash.qsf";
  const qsfUrl = `${BASE_PATH}${qsfPath}`;
  (async () => {
    try {
      const res = await fetch(`${BASE_PATH}quartus/open`, { method: "POST" });
      const data = await res.json().catch(() => ({}));
      if (!res.ok || data.success !== true) {
        throw new Error(data.message || `HTTP ${res.status}`);
      }
      showToast("Requested Quartus open (MuseDash.qsf)");
    } catch (err) {
      console.warn("openQuartus failed, fallback to direct download", err);
      showToast("Backend unavailable, downloading MuseDash.qsf for manual open");
      window.open(qsfUrl, "_blank");
    }
  })();
}

function generateRandomChart(auto = false) {
  if (els.randomStatus) els.randomStatus.textContent = "生成中（调用 chart_engine Random）...";
  if (els.randomPreview) els.randomPreview.innerHTML = "";
  if (els.randomData) els.randomData.textContent = "等待 chart_analysis 输出 summary JSON";
  if (els.randomMeta) els.randomMeta.textContent = "BPM: -- · 时长: --:--";
  if (els.randomCardImage) els.randomCardImage.src = RANDOM_COVER;
  if (auto) {
    state.randomGenerated = true;
  }
  (async () => {
    const ok = await runGenerateRandom();
    if (!ok) {
      state.randomReady = false;
      if (els.randomStatus) els.randomStatus.textContent = "生成失败，仍可尝试开始或重试生成";
      showToast("Random 谱面生成失败（占位）");
      return;
    }

    // 生成成功后触发一次 chart_analysis，再加载预览
    try {
      await triggerChartAnalysisRun(els.randomStatus);
      await loadRandomPreview();
      state.randomReady = true;
      if (els.randomStatus) els.randomStatus.textContent = "生成与分析完成";
      showToast("Random 谱面生成并分析完成");
    } catch (err) {
      console.warn("Random chart_analysis failed", err);
      state.randomReady = true; // 仍允许启动，但提示分析失败
      if (els.randomStatus) els.randomStatus.textContent = "生成完成，但 chart_analysis 失败，请检查后台";
      showToast("Random 已生成，但 chart_analysis 失败");
    }
  })();
}

async function refreshRandomAnalysis() {
  if (els.randomStatus) els.randomStatus.textContent = "手动刷新分析...";
  try {
    await triggerChartAnalysisRun(els.randomStatus);
    await loadRandomPreview();
    if (els.randomStatus) els.randomStatus.textContent = "分析完成，预览已更新";
    showToast("随机谱面分析已刷新");
  } catch (err) {
    console.warn("refreshRandomAnalysis failed", err);
    if (els.randomStatus) els.randomStatus.textContent = "分析刷新失败，请检查后台";
    showToast("随机谱面分析刷新失败");
  }
}

function applyRandomSelection() {
  if (!state.randomReady) {
    showToast("请先生成 Random 谱面");
    return;
  }
  if (els.randomStatus) els.randomStatus.textContent = "调用 chart_engine 处理中：Random...";
  (async () => {
    const ok = await runChartEngine("Random");
    if (ok) {
      showToast("写入成功：Random");
      if (els.randomStatus) els.randomStatus.textContent = "写入成功：Random";
    } else {
      showToast("写入失败：Random");
      if (els.randomStatus) els.randomStatus.textContent = "写入失败：Random";
    }
  })();
}

function openRandomQuartus() {
  if (!state.randomReady) {
    showToast("请先生成 Random 谱面");
    return;
  }
  openQuartus();
}

function playMusicSync(chartName) {
  if (!chartName) {
    showToast("缺少曲目名称");
    return;
  }
  // backend player: ensure单实例，先请求 stop 再启动
  const url = `${BASE_PATH}music_sync/play?name=${encodeURIComponent(chartName)}`;
  (async () => {
    try {
      // 先尝试停止已有的任务（若无则忽略）
      await fetch(`${BASE_PATH}music_sync/stop`, { method: "POST" }).catch(() => {});

      const res = await fetch(url, { method: "POST" });
      const data = await res.json().catch(() => ({}));
      if (!res.ok || data.success !== true) {
        throw new Error(data.message || `HTTP ${res.status}`);
      }
      showToast(`已触发软硬协同播放：${chartName}`);
    } catch (err) {
      console.warn("playMusicSync failed", err);
      showToast("软硬协同播放失败，请检查后端服务");
    }
  })();
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
    const cacheBust = Date.now();
    const images = (entry.files || []).map(
      (f) => `${BASE_PATH}chart_analysis/outputs/${f}?t=${cacheBust}`
    );
    const summaryUrl = entry.summary
      ? `${BASE_PATH}chart_analysis/outputs/${entry.summary}?t=${cacheBust}`
      : null;
    renderPreviewImages(images, els.randomPreview);
    renderSummary(summaryUrl, els.randomData);
    if (els.randomMeta) {
      const bpmVal = entry.bpm || entry.BPM || "--";
      const durVal = formatDurationForDisplay(entry.duration, entry.bpm || entry.BPM) || "--:--";
      const countVal = entry.note_count || entry.noteCount;
      const countText = typeof countVal === "number" ? ` · 物量: ${countVal}` : "";
      els.randomMeta.textContent = `BPM: ${bpmVal} · 时长: ${durVal}${countText}`;
    }
    if (els.randomCardImage) {
      els.randomCardImage.src = RANDOM_COVER;
      els.randomCardImage.alt = "Random cover";
    }
    return;
  } catch (err) {
    console.warn("loadRandomPreview failed", err);
    renderPreviewImages([`${BASE_PATH}chart_analysis/outputs/Random_dummy.png`], els.randomPreview);
    if (els.randomData) {
      els.randomData.textContent = "占位 summary：请检查 chart_analysis/outputs/Random_summary.json 是否可访问";
    }
    if (els.randomMeta) {
      els.randomMeta.textContent = "BPM: -- · 时长: --:--";
    }
    if (els.randomCardImage) {
      els.randomCardImage.src = RANDOM_COVER;
    }
  }
}

function bindEvents() {
  if (els.overlay) els.overlay.addEventListener("click", startExperience);
  if (els.btnChooseNormal) els.btnChooseNormal.addEventListener("click", () => {
    if (els.modeChooser) els.modeChooser.classList.add("hidden");
    if (els.modeBar) els.modeBar.classList.remove("hidden");
    switchMode("normal");
  });
  if (els.btnChooseRandom) els.btnChooseRandom.addEventListener("click", () => {
    if (els.modeChooser) els.modeChooser.classList.add("hidden");
    if (els.modeBar) els.modeBar.classList.remove("hidden");
    switchMode("random");
  });
  if (els.btnModeNormal) els.btnModeNormal.addEventListener("click", () => switchMode("normal"));
  if (els.btnModeRandom) els.btnModeRandom.addEventListener("click", () => switchMode("random"));
  if (els.btnSelectNormal) els.btnSelectNormal.addEventListener("click", applyNormalSelection);
  if (els.btnOpenQuartus) els.btnOpenQuartus.addEventListener("click", openQuartus);
  if (els.btnPlayNormal) els.btnPlayNormal.addEventListener("click", () => playMusicSync(state.selectedChart?.name));
  if (els.btnGenerateRandom) els.btnGenerateRandom.addEventListener("click", generateRandomChart);
  if (els.btnSelectRandom) els.btnSelectRandom.addEventListener("click", applyRandomSelection);
  if (els.btnOpenRandom) els.btnOpenRandom.addEventListener("click", openRandomQuartus);
  if (els.btnPlayRandom) els.btnPlayRandom.addEventListener("click", () => playMusicSync("Random"));
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
  // 如果是 file:// 直接打开，退回本地服务默认端口，保证请求能打到后端
  return "http://127.0.0.1:8000/";
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
