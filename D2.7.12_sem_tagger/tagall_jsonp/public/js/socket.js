var socket = new easyXDM.Socket({
	onMessage: function(m, o) {
		$('q').value = m;
		send_searches(m);
	}
});
