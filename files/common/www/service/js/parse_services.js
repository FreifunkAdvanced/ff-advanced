function services(json) {
    /// class helpers
    // human readable class name
    var class_name = {
	storage: "Netzlaufwerke",
	internet: "Internetzug&auml;nge",
	game: "Gameserver"
    };
    // table header
    var table = {
	storage: 
	      '<th>Laufwerk</th>'
	    + '<th>Kapazit&auml;t</th>'
	    + '<th>Daten</th>'
	    + '<th colspan=2 align="right">beschreibbar?</th>',
	internet: '<th>Mesh IP</th>'
	    + '<th>Public IP</th>'
	    + '<th>Downstream</th>'
	    + '<th>Upstream</th>',
	game: '<th>Server</th><th>Spieler</th>'
    };
    // table row
    var row = {
	storage: function(v) {
	    return '<td>'
		+ (v.desc != ''
		   ? ('<a href="' + v.url + '">' 
		      + v.desc + '<br />'
		      + '<small>' + v.url + '</small>'
		      + '</a>')
		   : ('<a href="' + v.url + '">' 
		      + v.url
		      + '</a>'))
		+ '</td><td>'
		+ (v.capacity ? SISuffixify(v.capacity) + 'B' : '')
		+ '</td><td>'
		+ (v.used ? SISuffixify(v.used) + 'B' : '')
		+ '</td><td>'
		+ ((v.used && v.capacity) 
		   ? (v.used / v.capacity * 100).toPrecision(2) + '%' 
		   : '')
		+ '</td><td>'
		+ ((v.custom3 == 'true')  ? '<i class="icon-ok"></i>' : '')
		+ ((v.custom3 == 'false') ? '<i class="icon-remove"></i>' : '')
		+ '</td>';
	},
	internet: function(v) {
	    return '<td>'
		+ (v.desc != ''
		   ? v.desc
		   : v.url.substr(7))
		+ '</td><td>'
		+ (v.public_ip ? v.public_ip : '')
		+ '</td><td>'
		+ (v.downstream ? SISuffixify(v.downstream * 8) + 'b/s' : '')
		+ '</td><td>'
		+ (v.upstream ? SISuffixify(v.upstream * 8) + 'b/s' : '')
		+ '</td>';
	},
	game: function(v) {
	    return '<td>'
		+ (v.desc != ''
		   ? ('<a href="' + v.url + '">' 
		      + v.desc + '<br />'
		      + '<small>' + v.url + '</small>'
		      + '</a>')
		   : ('<a href="' + v.url + '">' 
		      + v.url
		      + '</a>'))
	    	+ '</td><td>'
		+ (v.players ? v.players : '')
		+ '</td>';
	}
    };
    // mini row: emit one line per class (not one per service)
    var miniRow = {
	storage: function(c) {
	    var cap = sum(c, 'capacity');
	    return c.length
		+ ' <a href="/services.html#storage">Netzlaufwerke</a>'
		+ ((cap) ? ' (' + SISuffixify(cap) + 'B)' : '');
	},
	internet: function(c) {
	    var up   = sum(c, 'upstream');
	    var down = sum(c, 'downstream');
	    var stream = function(dir, amount) {
		return amount
		    ? ('<i class="icon-arrow-' + dir + '"></i> '
		       + SISuffixify(amount * 8) + 'b')
		    : '';
	    }		    
	    return c.length
		+ ' <a href="/services.html#internet">Internetzug&auml;nge</a>'
		+ ((up || down)
		   ? (' ('
		      + stream('down', down)
		      + ((up && down) ? ' / ' : '')
		      + stream('up', up)
		      + ')')
		   : '');
	},
	game: function(c) {
	    var pl = sum(c, 'players');
	    return c.length
		+ ' <a href="/services.html#game">Gameserver</a>'
		+ ((pl) ? ' (' + pl + ' <i class="icon-user"></i>)' : '');

	}
    };
    // aliases for customX values
    var parseCustom = {
	storage: ['capacity', 'used', 'writable'],
	internet: ['public_ip', 'upstream', 'downstream'],
	game: ['players']
    };

    /// parse JSON
    var srv = {};
    $.each(json, function(k,v) {
	var cn = v['class'];
	for (var i=1; i<4; i++) {
	    var custom = v['custom' + i];
	    if (parseCustom[cn] && parseCustom[cn][i-1] 
		&& custom && custom != '')
		v[parseCustom[cn][i-1]] = custom;
	}
	if (!srv[cn])
	    srv[cn] = [];
	srv[cn].push(v);
    });

    /// helpers
    function SISuffixify(x) {
	suffix_char = ['', 'K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y'];
	suffix = 0;
	for (; x > 1000; x /= 1000, suffix++);
	return x.toPrecision(3) + '&nbsp;' + suffix_char[suffix];
    }

    function sum(container, key) {
	var sum = 0;
	$.each(container, function(idx, obj) {
	    if (obj[key])
		sum += +obj[key];
	});
	return sum > 0 ? sum : undefined;
    }

    /// return: data + drawing functions
    return {
	data: srv,
	drawContainer: function(elem) {
	    $.each(srv, function(cn, services) {
		var tbody = '';
		$.each(services, function(i,v) {
		    tbody = tbody + '<tr>' + row[cn](v) + '</tr>';
		});
		elem.append(
		    '<div class="span6">' 
			+ '<h3>' + class_name[cn] + '</h3>' 
			+ '<table class="table table-striped">'
			+ '<thead><tr>'
			+ table[cn]
			+ '</tr></thead>'
			+ '<tbody>' + tbody + '</tbody>'
			+ '</table>'
			+ '</div>'
		);
	    })},
	drawLine: function(elem) {
	    $.each(srv, function(cn, services) {
		elem.append('<li>' + miniRow[cn](services) + '</li>');
	    });
	}	    
    };
}
