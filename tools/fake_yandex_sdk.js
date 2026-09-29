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
			payments: (() => {
				const catalog = [['starter_pack', 49], ['no_ads', 149], ['gold_pickaxe', 199],
					['coins_small', 29], ['coins_bag', 99], ['coins_chest', 249]];
				let held = JSON.parse(localStorage.getItem('fake_purchases') || '[]');
				let n = held.length;
				const keep = () => localStorage.setItem('fake_purchases', JSON.stringify(held));
				return {
					getCatalog() { return Promise.resolve(catalog.map(([id, v]) => ({ id, price: v + ' YAN', priceValue: String(v), priceCurrencyCode: 'YAN', getPriceCurrencyImage() { return '/icon.png'; } }))); },
					purchase({ id }) { console.log('FAKE purchase', id); if (id === 'coins_small') return Promise.reject(new Error('FAKE cancelled')); const p = { productID: id, purchaseToken: 'fake-' + (++n) }; held.push(p); keep(); return Promise.resolve(p); },
					getPurchases() { return Promise.resolve(held.slice()); },
					consumePurchase(token) { console.log('FAKE consume', token); held = held.filter((p) => p.purchaseToken !== token); keep(); return Promise.resolve(); },
				};
			})(),
			leaderboards: { setScore(b, s) { console.log('FAKE setScore', b, s); return Promise.resolve(); } },
		};
		window.FAKE_SDK = sdk;
		return Promise.resolve(sdk);
	},
};
