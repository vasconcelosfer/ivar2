local simplehttp = require'simplehttp'
local html2unicode = require'html'

local trim = function(s)
	if(not s) then return end
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

local handler = function(queue, info)
	local query = info.query
	local path = info.path

	if((query and query:match('sku=%d+')) or (path and path:match('/[^/]+/%d+'))) then
		simplehttp(
			info.url,

			function(data, url, response)
				local ins = function(out, fmt, ...)
					for i=1, select('#', ...) do
						local val = select(i, ...)
						if(type(val) == 'nil' or val == -1) then
							return
						end
					end

					table.insert(
						out,
						string.format(fmt, ...)
					)
				end

				local out = {}
				local name = data:match('<h1 class="main%-header" itemprop="name">([^<]+)</h1>')
				local desc = data:match('<h3 class="secondary%-header" itemprop="description">([^<]+)</h3>')
				local price = data:match('<span itemprop="price"[^>]+>([^<]+)</span>')
				local storage = data:match('<span class="stock%-details">(.-)</span>')
				local bomb = data:match('<div class="bomb">.-<div class="value">([^<]+)</div>')

				ins(out, '\002%s\002: ', html2unicode(name))
				if(desc) then
					ins(out, '%s ,', html2unicode(desc))
				end

				if(price) then
					ins(out, '\002%s\002 ', trim(price))
				end

				local extra = {}
				if(bomb) then
					bomb = trim(bomb)
					if(bomb:sub(1, 1) == '-') then
						bomb = bomb:sub(2)
					end

					ins(extra, '%s off', bomb)
				end

				if(storage) then
					storage = html2unicode(storage)
					storage = trim(storage:gsub('<%/?[%w:]+.-%/?>', ''))
					if(storage:sub(-1) == '.') then
						storage = storage:sub(1, -2)
					end
					ins(extra, '%s', storage)
				end

				if(#extra > 0) then
					ins(out, '(%s)', table.concat(extra, ', '))
				end

				queue:done(table.concat(out, ''))
			end
		)

		return true
	end
end

customHosts['komplett%.no'] = handler
customHosts['komplett%.dk'] = handler
customHosts['komplett%.se'] = handler
customHosts['inwarehouse%.se'] = handler
customHosts['mpx%.no'] = handler
