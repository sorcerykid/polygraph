local persistence = { 0, 0.2, 0.4, 0.6, 0.8, 1.0 }
local octaves = { 1, 2, 3, 4, 5, 6, 8 }
local scale = { 0.1, 0.2, 0.3, 0.4, 0.5, 1, 1.5, 2, 3, 4, 5, 10 }

minetest.register_chatcommand( "nt", {
	description = "Test output of 2d perlin noise functions interactively",
	func = function( name, param )
		local meta = { o_idx = 1, p_idx = 1, s_idx = 10, page = 0 }

		local get_formspec = function( )

			local noise = PerlinNoise( 144138, octaves[ meta.o_idx ], persistence[ meta.p_idx ], scale[ meta.s_idx ] )  -- seed, octaves, persistence, scale
			local graph = SimpleChart( { }, {
				y_range = 8,
				y_start = -2,
				y_scale = 0.5,
				vert_int = 0.5,
				vert_off = 5.5,
				x_start = 0,
				on_plot_y = function( y, y_index, v_min, v_max, prop )
					if y_index < 0 then
						prop.idx_color = "#FF4444"
					elseif y_index > 0 then
						prop.idx_color = "#44FF44"
					end
				end,
				on_plot_x = function( x, x_index, v_min, v_max, v, prop )
					prop.idx_label = tostring( x + meta.page * 5 )
					prop.idx_label = string.format( "%3d", x ) -- hack for centering
					if v < 0 then
						prop.tag_color = "#AAAAAA"
						prop.bar_color = "#AAAAAA"
					end
					if x_index < 0 then
						prop.idx_color = "#FF0000"
					end
					return v
                                end
			} )

			local formspec = "size[12,8]"
				.. default.gui_bg_img
				.. string.format( "label[0.5,0.4;%s:]", "Persistence" )
				.. string.format( "dropdown[2.5,0.3;1.5,1;persistence;%s;%d]", table.concat( persistence, "," ), meta.p_idx )
				.. string.format( "label[4.5,0.4;%s:]", "Octaves" )
				.. string.format( "dropdown[6,0.3;1.5,1;octaves;%s;%d]", table.concat( octaves, "," ), meta.o_idx )
				.. string.format( "label[8.5,0.4;%s:]", "Scale" )
				.. string.format( "dropdown[10,0.3;1.5,1;scale;%s;%d]", table.concat( scale, "," ), meta.s_idx )

				.. "button[4,7;1,1;prev;<<]"
				.. string.format( "label[5.5,7.3;Page %d]", meta.page + 1 )
				.. "button[7,7;1,1;next;>>]"

			for x = 0, 19 do
				graph.push( noise:get2d( { x = x + meta.page * 5, y = 0 } ) / octaves[ meta.o_idx ] )
			end

			return formspec .. graph.draw( GRAPH_TYPEDOT, 0, 0 )
		end
		local on_close = function( meta, player, fields )
			if fields.quit then return end

			if fields.prev and meta.page > 0 then
				meta.page = meta.page - 1
			elseif fields.next and meta.page < 500 then
				meta.page = meta.page + 1
			elseif fields.persistence then
				meta.p_idx = get_index( persistence, tonumber( fields.persistence ) ) or 1
			elseif fields.octaves then
				meta.o_idx = get_index( octaves, tonumber( fields.octaves ) ) or 1
			elseif fields.scale then
				meta.s_idx = get_index( scale, tonumber( fields.scale ) ) or 1
			end
			minetest.update_form( player, get_formspec( ) )
		end

		minetest.create_form( meta, name, get_formspec( ), on_close )
	end
} )
