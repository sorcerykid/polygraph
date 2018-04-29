--------------------------------------------------------
-- Minetest :: Polygraph Mod v1.1 (polygraph)
--
-- See README.txt for licensing and release notes.
-- Copyright (c) 2016-2018, Leslie Ellen Krause
--
-- ./games/just_test_tribute/mods/polygraph/init.lua
--------------------------------------------------------

GRAPH_TYPEBAR = 0
GRAPH_TYPESEG = 1
GRAPH_TYPEDOT = 2

function get_index( t, x )
	for i, v in ipairs( t ) do
		if v == x then return i end
	end
end

CustomChart = function( dataset, def )
	local self = { }
	local horz_off = def.horz_off or 1
	local vert_off = def.vert_off or 6
	local horz_int = def.horz_int or 0.5

	local x_range = def.x_range or 20
	local x_scale = def.x_scale or 1
	local x_start = def.x_start or 0		-- starting position of x-axis
	local x_shift = def.x_shift or 0		-- scroll position of x-axis

	local on_plot = def.on_plot or function( x, x_index, horz, vert, v )
		return string.format( "label[%0.1f,%0.1f;%s]", horz, vert, tostring( v ) )
	end
	
	self.draw = function( x_shift, meta )
		local formspec = ""

		-- x-axis
		for x = 0, x_range - 1 do
			local x_index = x_start + x * x_scale + x_shift

			if x_index >= 0 and x_index < #dataset then
				local v = dataset[ x_index + 1 ]

				if on_plot then
					 formspec = formspec .. on_plot( x, x_index, horz_off + x * horz_int, vert_off, v, meta )
				end
			end
		end

		return formspec
	end

	return self
end

SimpleChart = function( dataset, def )
	local self = { }

	-- graph parameters
	local vert_off = def.vert_off or 6		-- vertical offset of x-axis from formspec top
	local vert_int = def.vert_int or 1		-- vertical spacing between y-axis values
	local vert_pad = def.vert_pad or 0.5		-- vertical padding of x-axis values
	local horz_off = def.horz_off or 1		-- horizontal offset of y-axis from formspec left
	local horz_int = def.horz_int or 0.5		-- horizontal spacing between x-axis values
	local horz_pad = def.horz_pad or 0.6		-- horizontal padding of y-axis values

	local box_off = 0.2
	local vert_dec = def.vert_dec or 1		-- decimal places for y-axis values

	local bar_color = def.bar_color or "#CCCCCC"
	local box_color = def.box_color or "#444444"
	local ref_color = def.ref_color or "#666666"
	local tag_color = def.tag_color or "#FFFFFF"
	local idx_color = def.idx_color or "#FFFFFF"

	-- data parameters
	local y_range = def.y_range or 4		-- number of data points along y-axis
	local y_start = def.y_start or -1		-- starting position of y-axis
	local y_scale = def.y_scale or 0.5		-- scale factor of y-axis
	local y_shift = def.y_shift or 0		-- scroll position of y-axis
	local x_range = def.x_range or 20		-- number of data points along the x-axis
	local x_scale = def.x_scale or 1		-- scale factor of x-axis (integer of 1 or greater)
	local x_start = def.x_start or 0		-- starting position of x-axis
	local x_shift = def.x_shift or 0		-- scroll position of x-axis
	
	local on_plot_x = def.on_plot_x
	local on_plot_y = def.on_plot_y

	self.draw = function( graph_type, x_shift, y_shift, meta )
		-- eventually move these into meta for use by the plot functions
		local v_max = y_start + y_range * y_scale + y_shift
		local v_min = y_start
		local x_max = x_start + x_range * x_scale + x_shift
		local x_min = x_start

		local formspec = string.format( "box[%0.1f,%0.1f;%0.1f,%0.1f;%s]",
			horz_off, vert_off - y_range * vert_int + box_off, x_range * horz_int, y_range * vert_int, box_color )

		-- y-axis
		for y = 0, y_range do
			local y_index = y_start + y * y_scale + y_shift

			local prop = {
				idx_label = string.format( "%0." .. vert_dec .. "f", y_index ),
				idx_color = idx_color,
				ref_color = ref_color,
				ref_width = 0.05,
			}

			if on_plot_y then
				on_plot_y( y, y_index, v_min, v_max, prop, meta )
			end

			if prop.idx_label ~= "" then
				formspec = formspec .. string.format( "label[%0.2f,%0.2f;%s]",
					horz_off - horz_pad, vert_off - y * vert_int, minetest.colorize( prop.idx_color, prop.idx_label ) )
			end
			if prop.ref_width > 0 then
				formspec = formspec .. string.format( "box[%0.2f,%0.2f;%0.1f,%0.2f;%s]",
					horz_off, vert_off - y * vert_int + box_off, x_range * horz_int, prop.ref_width, prop.ref_color )
			end
		end

		-- x-axis
		for x = 0, x_range - 1 do
			local x_index = x_start + x * x_scale + x_shift

			if x_index >= 0 and x_index < #dataset then
				local v = dataset[ x_index + 1 ]
				local prop = {
					idx_label = tostring( x_index ),
					idx_color = idx_color,
					bar_color = bar_color,
					tag_label = string.format( "%0." .. vert_dec .. "f", v ),
					tag_color = tag_color,
				}

				if on_plot_x then
					 v = on_plot_x( x, x_index, v_min, v_max, v, prop, meta )
				end

				if graph_type == GRAPH_TYPEBAR and v then
					if v_min <= 0 and v_max >= 0 then
						local z = -y_start / y_scale * vert_int

					--	if v_min > 0 then
					--		z = z + v_min / y_scale * vert_int
					--	elseif v_max < 0 then
					--		z = z - v_max / y_scale * vert_int
					--	end

						if v >= 0 then
							local height = math.min( v_max, v / y_scale * vert_int )

							formspec = formspec .. string.format( "box[%0.2f,%0.2f;%0.1f,%0.2f;%s]",
								horz_off + x * horz_int + horz_int * 0.1, vert_off - z - height + box_off, horz_int * 0.8, height + 0.05, prop.bar_color )

							if prop.tag_label ~= "" then
								formspec = formspec .. string.format( "label[%0.2f,%0.1f;%s]",
									horz_off + x * horz_int, vert_off - z - height - 0.3, minetest.colorize( prop.tag_color, prop.tag_label ) )
							end
						else
							local height = math.max( v_min, -v / y_scale * vert_int )

							formspec = formspec .. string.format( "box[%0.2f,%0.2f;%0.1f,%0.2f;%s]",
								horz_off + x * horz_int + horz_int * 0.1, vert_off - z + box_off, horz_int * 0.8, height, prop.bar_color )

							if prop.tag_label ~= "" then
								formspec = formspec .. string.format( "label[%0.2f,%0.1f;%s]",
									horz_off + x * horz_int, vert_off - z + height + 0.3, minetest.colorize( prop.tag_color, prop.tag_label ) )
							end
						end

					end
				elseif graph_type == GRAPH_TYPESEG and v then
					if v >= v_min and v <= v_max then
						local height = ( v - y_start ) / y_scale * vert_int

						formspec = formspec .. string.format( "box[%0.2f,%0.2f;%0.1f,0.1;%s]",
								horz_off + x * horz_int, vert_off - height + box_off, horz_int, prop.bar_color )

						if prop.tag_label ~= "" then
							formspec = formspec .. string.format( "label[%0.2f,%0.1f;%s]",
								horz_off + x * horz_int, vert_off - height - 0.3, minetest.colorize( prop.tag_color, prop.tag_label ) )
						end
					end
				elseif graph_type == GRAPH_TYPEDOT and v then
					if v >= v_min and v <= v_max then
						local height = ( v - y_start ) / y_scale * vert_int

						formspec = formspec .. string.format( "box[%0.2f,%0.2f;0.2,0.2;%s]",
								horz_off + x * horz_int + horz_int / 2 - 0.1, vert_off - height - 0.1 + box_off, prop.bar_color )

						if prop.tag_label ~= "" then
							formspec = formspec .. string.format( "label[%0.2f,%0.1f;%s]",
								horz_off + x * horz_int + horz_int / 2 - 0.1, vert_off - height - 0.4, minetest.colorize( prop.tag_color, prop.tag_label ) )
						end
					end
				end

				if prop.idx_label ~= "" then
			--		formspec = formspec .. string.format( "label[%0.2f,%0.1f;%s]",
			--			horz_off + x * horz_int + horz_int / 2 - 0.1, vert_off + vert_pad, minetest.colorize( prop.idx_color, prop.idx_label ) )
					formspec = formspec .. string.format( "label[%0.2f,%0.1f;%s]",
						horz_off + x * horz_int, vert_off + vert_pad, minetest.colorize( prop.idx_color, prop.idx_label ) )
				end
			end
		end

		return formspec
	end

	self.push = function( value )
		table.insert( dataset, value )
	end

	return self
end
