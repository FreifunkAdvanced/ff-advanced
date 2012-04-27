// adapt to small window sizes .. TODO: solution that sucks less
var sizeAdaptor = function() {
    if ($(window).width() < 800) {
	$('.tabs-left')
	    .removeClass('tabs-left')
	    .addClass('tabs-above');
    }else{
	$('.tabs-above')
	    .removeClass('tabs-above')
	    .addClass('tabs-left');
    }
}
sizeAdaptor();
$(window).resize(sizeAdaptor);

/// helper functions to hold & update data

function data(key) {
    if (typeof data[key] == "undefined") {
	var f = function(val) { fillData(key, val); };
	data[key] = $.Deferred().then(f, [], f);	
    }
    return data[key];
}

function fillData(key, val, def) {
    $('pre.data-' + key
      + ',p.data-' + key
      + ',span.data-' + key)
	.empty().append(val ? val : def)
	.removeClass('loading');
    if (val) {
	$('input.data[name=' + key + ']').val(val);
	$('.only-' + key)
	    .removeClass('hidden only-' + key)
	    .addClass('only-' + key)
	    .attr('class', function(i, ca) {
		if (ca.indexOf('only-') == -1) this.css('display', 'block');
	    });
    }else{
	$('.has-' + key)
	    .removeClass('has-' + key)
	    .addClass('only-' + key)
	    .css('display', 'none');
    }
}

/// load data

var loadBootstrap = $.ajax({url: "js/bootstrap.min.js", dataType: "script", cache: true});
var loadCfg = {};
$.each(['client_net', 'cfg_client', 'cfg_router', 'node_position'],
       function(i,name) {
	  loadCfg[name] = $.getJSON('cgi-bin/' + name + '.json')
	      .done(function(res) {
		  $.each(res, function(k,v) { data(k).notify(v); });
	      });
      });

/// add event handlers

var formChangeHandler = function() {
    $(this.form).find('[type="submit"]')
	.removeClass('disabled btn-success btn-danger')
	.addClass('btn-primary');
};
var formSubmitHandler = function() {
    form = this;
    $('[type="submit"].btn-success')
	.removeClass('btn-success')
	.addClass('disabled');
    btn = $(form).find('[type="submit"]');
    btn.addClass('disabled');
    $(form).children('div.alert').remove();
    $.post(form.action, $(form).serialize())
	.done(function(res) { 
	    btn.addClass('btn-success')
		.removeClass('btn-primary');
	    $(form).find('.alert').remove();
	    $.each(res, function(k,v) { data(k).notify(v); });
	    if (form.id == 'geo')
		$.getJSON('cgi-bin/node_position.json')
		.always(function() {
		    $.each(['lon', 'lat', 'street'], function(i,name) { 
			data('router_pos_' + name).notify(''); });
		}).done(function(res) {
		    $.each(res, function(k,v) { data(k).notify(v); });
		});
	})
	.fail(function(v) {
	    btn.addClass('btn-danger');
	    $(form).prepend('<div class="alert alert-error">' + v.responseText + '</div>');
	});
    return false;
}
$('form.well input')
    .change(  formChangeHandler)
    .keypress(formChangeHandler)
$('form.well')
    .submit(formSubmitHandler);

/// add data handlers
$.when(loadCfg['client_net']).done(function(cn) {
    fillData('net_desc',
	'Im Moment bist du per '
	    + (cn.wired ? 'Ethernet' : 'WLAN')
	    + ' mit '
	    + (cn.router_name
	       ? 'dem Router <strong><span class="data-router_name">' + cn.router_name + '</span></strong>'
	       : '<span class="data-router_name">einem unbenannten Router</span>')
	    + ' verbunden.');
});

$.when(loadBootstrap).done(function() {
    $('#tooltip-mac').popover(
	{title: "Was ist eine MAC-Adresse?", content: "<p>Jede "
	 + "Netzwerkkarte hat eine weltweit eindeutige Nummer: die "
	 + "MAC-Adresse. Im Gegensatz zu einer IP-Adresse &auml;ndert sich diese nicht.</p>"
	 + "<p>Wenn dein Computer mit verschiedenen Netzwerkkarten auf "
	 + "das Frei&shy;funk&shy;netz&shy;werk zugreift (zum Beispiel per Kabel- und per "
	 + "Drahtlosnetzwerk), dann werden auch verschiedene MAC-Adres&shy;sen &uuml;bertragen. "
	 + "Du musst die Einstellungen f&uuml;r jede MAC-Adresse wiederholen.</p>", 
	 delay: 50})});
