// FAKE Yandex SDK for local bridge testing — never ship.
window.YaGames = {
	init() {
		const handlers = {};
		let store = {};
		const sdk = {
			environment: { i18n: { lang: 'ru' } },
			on(name, fn) { handlers[name] = fn; },
			_emit(name) { handlers[name] && handlers[name](); },
			features: {
				LoadingAPI: { ready() { console.log('FAKE LoadingAPI.ready'); } },
				GameplayAPI: { start() { console.log('FAKE gameplay start'); }, stop() { console.log('FAKE gameplay stop'); } },
			},
			adv: {
				showFullscreenAdv({ callbacks }) { console.log('FAKE fullscreen'); callbacks.onOpen(); setTimeout(() => callbacks.onClose(true), 500); },
				showRewardedVideo({ callbacks }) { console.log('FAKE rewarded'); callbacks.onOpen(); handlers.game_api_pause && handlers.game_api_pause(); setTimeout(() => { callbacks.onRewarded(); callbacks.onClose(); handlers.game_api_resume && handlers.game_api_resume(); }, 1500); },
			},
			getPlayer() { return Promise.resolve({
				getData() { return Promise.resolve(store); },
				setData(d) { store = d; return Promise.resolve(); },
			}); },
			leaderboards: { setScore(b, s) { console.log('FAKE setScore', b, s); return Promise.resolve(); } },
		};
		window.FAKE_SDK = sdk;
		return Promise.resolve(sdk);
	},
};
