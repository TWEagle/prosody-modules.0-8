local stanza = require"util.stanza".stanza;
local tostring, tonumber = tostring, tonumber;
local type = type;
local pairs = pairs;

local xmlns_rsm = 'http://jabber.org/protocol/rsm';

local element_parsers;

do
	local function xs_int(st)
		return tonumber((st:get_text()));
	end
	local function xs_string(st)
		return st:get_text();
	end

	element_parsers = {
		after = xs_string;
		before = function(st)
			return st:get_text() or true;
		end;
		max = xs_int;
		index = xs_int;

		first = function(st)
			return { index = tonumber(st.attr.index); st:get_text() };
		end;
		last = xs_string;
		count = xs_int;
	}
end

local element_generators = setmetatable({
	first = function(st, data)
		if type(data) == "table" then
			st:tag("first", { index = data.index }):text(data[1]):up();
		else
			st:tag("first"):text(tostring(data)):up();
		end
	end;
}, {
	__index = function(_, name)
		return function(st, data)
			st:tag(name):text(tostring(data)):up();
		end
	end;
});


local function parse(stanza)
	local rs = {};
	for tag in stanza:childtags() do
		local name = tag.name;
		local parser = name and element_parsers[name];
		if parser then
			rs[name] = parser(tag);
		end
	end
	return rs;
end

local function generate(t)
	local st = stanza("set", { xmlns = xmlns_rsm });
	for k,v in pairs(t) do
		if element_parsers[k] then
			element_generators[k](st, v);
		end
	end
	return st;
end

local function get(st)
	local set = st:get_child("set", xmlns_rsm);
	if set and #set.tags > 0 then
		return parse(set);
	end
end

return { parse = parse, generate = generate, get = get };
