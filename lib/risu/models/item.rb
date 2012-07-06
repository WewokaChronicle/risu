module Risu
	module Models

		# Item Model
		#
		# @author Jacob Hammack <jacob.hammack@hammackj.com>
		class Item < ActiveRecord::Base
			belongs_to :host
			belongs_to :plugin

			class << self

				# Queries for all risks in the database
				#
				# @return [ActiveRecord::Relation] with the query results
				def risks
					where(:severity => [0,1,2,3,4])
				end

				# Queries for all the high risks in the database
				#
				# @return [ActiveRecord::Relation] with the query results
				def critical_risks
					where(:severity => 4)
				end

				# Queries for all the high risks in the database
				#
				# @return [ActiveRecord::Relation] with the query results
				def high_risks
					where(:severity => 3)
				end

				# Queries for all the medium risks in the database
				#
				# @return [ActiveRecord::Relation] with the query results
				def medium_risks
					where(:severity => 2)
				end

				# Queries for all the low risks in the database
				#
				# @return [ActiveRecord::Relation] with the query results
				def low_risks
					where(:severity => 1)
				end

				# Queries for all the info risks in the database
				#
				# @return [ActiveRecord::Relation] with the query results
				def info_risks
					where(:severity => 0)
				end

				# Queries for all the unique Critical risks in the database
				#
				# @return [ActiveRecord::Relation] with the query results
				def critical_risks_unique
					where(:severity => 4).joins(:plugin).order("plugins.cvss_base_score").group(:plugin_id)
				end

				# Queries for all the unique high risks in the database
				#
				# @return [ActiveRecord::Relation] with the query results
				def high_risks_unique
					where(:severity => 3).joins(:plugin).order("plugins.cvss_base_score").group(:plugin_id)
				end

				# Queries for all the unique Critical findings and sorts them by count
				#
				# @return [ActiveRecord::Relation] with the query results
				def critical_risks_unique_sorted
					select("items.*").select("count(*) as count_all").where(:severity => 4).group(:plugin_id).order("count_all DESC")
				end

				# Queries for all the unique high findings and sorts them by count
				#
				# @return [ActiveRecord::Relation] with the query results
				def high_risks_unique_sorted
					select("items.*").select("count(*) as count_all").where(:severity => 3).group(:plugin_id).order("count_all DESC")
				end

				# Queries for all the unique medium risks in the database
				#
				# @return [ActiveRecord::Relation] with the query results
				def medium_risks_unique
					where(:severity => 2).joins(:plugin).order(:cvss_base_score).group(:plugin_id)
				end

				# Queries for all the unique medium findings and sorts them by count
				#
				# @return [ActiveRecord::Relation] with the query results
				def medium_risks_unique_sorted
					select("items.*").select("count(*) as count_all").where(:severity => 2).group(:plugin_id).order("count_all DESC")
				end

				# Queries for all the unique low risks in the database
				#
				# @return [ActiveRecord::Relation] with the query results
				def low_risks_unique
					where(:severity => 1).joins(:plugin).order(:cvss_base_score).group(:plugin_id)
				end

				# Queries for all the unique low findings and sorts them by count
				#
				# @return [ActiveRecord::Relation] with the query results
				def low_risks_unique_sorted
					select("items.*").select("count(*) as count_all").where(:severity => 1).group(:plugin_id).order("count_all DESC")
				end

				# Queries for all the unique info risks in the database
				#
				# @return [ActiveRecord::Relation] with the query results
				def info_risks_unique
					where(:severity => 0).joins(:plugin).order(:cvss_base_score).group(:plugin_id)
				end

				# Queries for all the unique info findings and sorts them by count
				#
				# @return [ActiveRecord::Relation] with the query results
				def info_risks_unique_sorted
					select("items.*").select("count(*) as count_all").where(:severity => 0).group(:plugin_id).order("count_all DESC")
				end

				# Queries for all the risks grouped by service type, used for the Vulnerbilities by Service graph
				#
				# @return [ActiveRecord::Relation] with the query results
				def risks_by_service(limit=10)
					select("items.*").select("count(*) as count_all").where("svc_name != 'unknown' and svc_name != 'general'").group(:svc_name).order("count_all DESC").limit(limit)
				end

				# Queries for all the Critical risks by plugin
				#
				# @param limit Limits the result to a specific number, default 10
				#
				# @return [ActiveRecord::Relation] with the query results
				def risks_by_plugin(limit=10)
					select("items.*").select("count(*) as count_all").joins(:plugin).where("plugin_id != 1").where(:severity => 4).group(:plugin_id).order("count_all DESC").limit(limit)
				end

				# Queries for all the Critical risks by host
				#
				# @param limit Limits the result to a specific number, default 10
				#
				# @todo add high/med/low_risks_by_host functions
				#
				# @return [ActiveRecord::Relation] with the query results
				def risks_by_host(limit=10)
					select("items.*").select("count(*) as count_all").joins(:host).where("plugin_id != 1").where(:severity => 4).group(:host_id).order("count_all DESC").limit(limit)
				end

				# @todo comment
				def critical_risks_by_host(limit=10)
					select("items.*").select("count(*) as count_all").joins(:host).where("plugin_id != 1").where(:severity => 4).group(:host_id).order("count_all DESC").limit(limit)
				end

				# @todo comment
				def high_risks_by_host(limit=10)
					select("items.*").select("count(*) as count_all").joins(:host).where("plugin_id != 1").where(:severity => 3).group(:host_id).order("count_all DESC").limit(limit)
				end

				# Queries for all the hosts with the Microsoft patch summary plugin (38153)
				#
				# @return [ActiveRecord::Relation] with the query results
				def ms_patches
					where(:plugin_id => 38153).joins(:host)
				end

				# Queries for all host with the Microsoft Update Summary plugin(12028)
				#
				# @return [ActiveRecord::Relation] with the query results
				def ms_update
					where(:plugin_id => 12028).joins(:host)
				end

				# Generates a Graph of all the risks by service
				#
				# @param limit Limits the result to a specific number, default 10
				#
				# @return [StringIO] Object containing the generated PNG image
				def risks_by_service_graph(limit=10)
					g = Gruff::Pie.new(GRAPH_WIDTH)
					g.title = sprintf "Top %d Services By Vulnerability", Item.risks_by_service(limit).all.count
					g.sort = false
					g.marker_count = 1
					g.theme = {
						:colors => %w(red orange yellow blue green purple black grey brown pink),
						:background_colors => %w(white white)
					}

					Item.risks_by_service(limit).all.each do |service|
						g.data(service.svc_name, Item.find(:all, :conditions => {:svc_name => service.svc_name}).count)
					end

					StringIO.new(g.to_blob)
				end

				#@todo comment
				def risks_by_service_graph_text
					"This graph is a representation of the findings found by service. This graph can help " +
					"understand what services are running on the network and if they are vulnerable, where " +
					"the risks are and how they should be protected.\n\n"
				end

				# Generates a Graph of all the risks by severity
				#
				# @return [StringIO] Object containing the generated PNG image
				def risks_by_severity_graph
					g = Gruff::Bar.new(GRAPH_WIDTH)
					g.title = "Risks By Severity"
					g.sort = false
					g.marker_count = 1
					g.theme = {
						:colors => %w(red orange yellow blue green purple black grey brown pink),
						:background_colors => %w(white white)
					}

					crit = Item.critical_risks.count
					high = Item.high_risks.count
					medium = Item.medium_risks.count
					low = Item.low_risks.count
					info = Item.info_risks.count

					if crit == nil then crit = 0 end
					if high == nil then high = 0 end
					if medium == nil then medium = 0 end
					if low == nil then low = 0 end
					if info == nil then info = 0 end

					g.data("Critical", crit, "purple")
					g.data("High", high, "red")
					g.data("Medium", medium, "orange")
					g.data("Low", low, "yellow")
					g.data("Informational", info, "blue")

					StringIO.new(g.to_blob)
				end

				#
				# @todo comment
				def stig_findings(categeory="I")
					where('plugin_id IN (:plugins)', :plugins => Plugin.where(:stig_severity => categeory).select(:id)).order("severity DESC")
				end

				# Generates a Graph of all the risks by severity
				#
				# @return [StringIO] Object containing the generated PNG image
				def stigs_severity_graph
					g = Gruff::Bar.new(GRAPH_WIDTH)
					g.title = "Stigs By Severity"
					g.sort = false
					g.marker_count = 1
					g.theme = {
						:colors => %w(purple red orange yellow blue green black grey brown pink),
						:background_colors => %w(white white)
					}

					i = Item.stig_findings("I").count
					ii = Item.stig_findings("II").count
					iii = Item.stig_findings("III").count

					if i == nil then i = 0 end
					if ii == nil then ii = 0 end
					if iii == nil then iii = 0 end

					g.data("Cat I", i, "purple")
					g.data("Cat II", ii, "red")
					g.data("Cat III", iii, "orange")

					StringIO.new(g.to_blob)
				end

				# @todo comment
				#
				def calculate_vulnerable_host_percent
					hosts_with_critical = Hash.new

					(Item.critical_risks.all + Item.high_risks.all).each do |item|
						ip = Host.find_by_id(item.host_id).name
						if hosts_with_critical[ip] == nil
							hosts_with_critical[ip] = 1
						end

						hosts_with_critical[ip] = hosts_with_critical[ip] + 1
					end

					host_percent = (hosts_with_critical.count.to_f / Host.all.count.to_f) * 100
				end

				# @todo comments
				#
				def ajective_for_risk_text risk_percent
					adjective = case risk_percent
						when 0..5
							"excellent"
						when 6..10
							"great"
						when 11..15
							"good"
						when 16..20
							"fair"
						else
							"poor"
					end
				end

				# @todo comments
				#
				def risk_text risk_percent
					percent_text = case risk_percent
						when 0..5.99
							"This implies that only a handful of computers are missing patches, and the current patch management is working well."
						when 6..10.99
							"This implies that there is a minor patch management issue. If there is a patch management system, it should be checked for problems. " +
							"Each host should also be inspected to be certain it can receive patches."
						when 11..15.99
							"This implies that there is a substantial patch management issue. If there is a patch management system, it should be checked for problems. " +
							"Each host should also be inspected to be certain it can receive patches."
						when 16..20
							"This implies that there is a significant patch management issue. If there is a patch management system, it should be checked for problems. " +
							"Each host should also be inspected to be certain it can receive patches."
						else
							"This implies that there is a critical patch management problem on the network. Any patch management solutions should " +
							"be inspected for issues and they should be corrected as soon as possible. Each host should also be inspected to be certain it can receive patches."
					end
				end

				# @todo change Report.title to a real variable
				# @todo rewrite this
				def risks_by_severity_graph_text
					host_percent = calculate_vulnerable_host_percent()
					adjective = ajective_for_risk_text(host_percent)
					risk_text = risk_text(host_percent)

					graph_text = "This bar graph is a representation of the findings by severity; the " +
					"graph shows that, overall, #{Report.title} has a #{adjective} handle on the patch " +
					"management of the network. "

					#graph_text = "This bar graph is a representation of the findings by severity; the " +
					#{}"graph shows that, Overall #{Report.title} needs to implement patch management and configuration management as a priority."

					#if adjective == "good" or adjective == "fair"
					#	graph_text << "But improvements in patch management could be made to ensure an excellent rating."
					#end

					graph_text << "\n\n"

					graph_text << "The majority of the critical findings were found on #{host_percent.round}% of the total assessed computers. #{risk_text}\n\n"

					graph_text << "The systems with critical vulnerabilities represent the largest threat to the network, " +
					"so patching this group is paramount to the overall network security. It only takes one vulnerability " +
					"to create a security incident.\n\n"

					graph_text << "It should be noted that low findings and open ports represent the discovery "
					graph_text << "of network services and open ports. Typically, these are not an indication of "
					graph_text << "a serious problem and pose little to no threat. However, the correlation of "
					graph_text << "data between the different severity levels could be used to determine degree "
					graph_text << "of vulnerability for a given system.\n"

					return graph_text
				end

				#sqlite only @todo @fix
				def top_10_sorted_raw
					raw = Item.joins(:plugin).where(:severity => 4).order("cast(plugins.cvss_base_score as real)").count(:all, :group => :plugin_id)
					data = Array.new

					raw.each do |vuln|
						row = Array.new
						plugin_id = vuln[0]
						count = vuln[1]

						row.push(plugin_id)
						row.push(count)
						data.push(row)
					end

					data = data.sort do |a, b|
						b[1] <=> a[1]
					end

					return data
				end

				def top_10_sorted
					#raw = Item.where(:severity => 3).count(:all, :group => :plugin_id)
					raw = Item.joins(:plugin).where(:severity => 4).order(:cvss_base_score).count(:all, :group => :plugin_id)
					data = Array.new

					raw.each do |vuln|
						row = Array.new
						plugin_id = vuln[0]
						count = vuln[1]

						name = Plugin.find_by_id(plugin_id).plugin_name

						row.push(name)
						row.push(count)
						data.push(row)
					end

					data = data.sort do |a, b|
						b[1] <=> a[1]
					end

					return data
				end

				# Returns a prawn pdf table for the top 10 notable findings
				#
				# @todo change this method to return a array/table and let the template render it
				# @todo rename to notable_table also
				#
				# @param output device to write the table to
				def top_10_table(output)
					headers = ["Description", "Count"]
					header_widths = {0 => (output.bounds.width - 50), 1 => 50}

					data = top_10_sorted

					output.table([headers] + data[0..9], :header => true, :column_widths => header_widths, :width => output.bounds.width) do
						row(0).style(:font_style => :bold, :background_color => 'cccccc')
						cells.borders = [:top, :bottom, :left, :right]
					end
				end

				# Queries for all unique risks and sorts them by count
				#
				# @return [ActiveRecord::Relation] with the query results
				def all_risks_unique_sorted
				    select("items.*").select("count(*) as count_all").group(:plugin_id).order("count_all DESC")
				end

			end
		end
	end
end
