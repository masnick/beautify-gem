require 'rubygems'
require 'json'
require 'psych'


module Beautify
  class Integer
    def self.percentage(value,total)
      pp value
      pp total
      ((value / total.to_f) * 1000).round/10.0
    end
  end

  class Float
    def self.p_round(p)
      r = (p.to_f*10000).round/10000.0
      return "<b>< 0.0001</b>" if r < 0.0001
      return "<b>#{r}</b>" if r <= 0.05
      return r
    end
  end

  class Stata
    class << self
      def run(options)
        # argv0 is stata output file (:data)
        # argv1 is template yaml file (:template)
        # argv2 is destination for html file (:output)

        v = File.open(options[:data], "r", :encoding => "UTF-8").read
        template_file = File.open(options[:template], "r").read

        v = '['+v[0,v.length-2].gsub('"',"'").gsub('||','"')+']'

        parsed = JSON.parse(v)


        output = Hash.new

        parsed.each do |table|
          out = ""
          if table['type'] == 'tab2'

            table['percents'] = Array.new
            tmp = Array.new
            table['values'].each_with_index do |row, i|
              row.each_with_index do |value, j|
                tmp[j] = 0 unless tmp[j]
                tmp[j] += value
              end
            end
            table['values'].each_with_index do |row, i|
              row.each_with_index do |value, j|
                table['percents'][i] = Array.new unless table['percents'][i]
                table['percents'][i][j] = ((table['values'][i][j] / tmp[j].to_f) * 10000).round/100.0
              end
            end

            total_n = table['values'].inject(0){|sum, v| sum += v.inject(0){|sum2, vv| sum2 += vv; sum2}}

            out << "<table>\n"
            out << "<!--\t<tr class=\"tophead\"><th></th><th colspan=\"#{table['colnames'].size}\">#{table['title'][1]}</th></tr>-->\n"
            out << "\t<tr class=\"tophead\"><th></th>#{table['colnames'].map{|n|"<th>"+n+"</th>"}.join}<th>Total</th></tr>\n"
            table['rownames'].each_with_index do |rowname, i|
              # next if i == 1 && table['rownames'].length == 2 # Display only first row if there are only two rows
              out << "\t<tr class=\"#{i % 2 == 0 ? 'even': ''}\">\n\t\t<th class=\"sidehead\">#{table['rownames'][i]}</th>"
              table['colnames'].each_with_index do |colname, j|
                out << "<td>#{table['percents'][i][j]}% (#{table['values'][i][j]})</td>\n"
              end

              # Row totals
              rowtotal = table['values'][i].inject(0){|sum,v| sum += v; sum}
              rowpercent = ((rowtotal / total_n.to_f) * 10000).round/100.0
              out << "<td class=\"rowtotal\">#{rowpercent}% (#{rowtotal})</td>"
              out << "\t</tr>\n"
            end
            
            # Column totals
            #out << "\t<tr class=\"coltotal #{!(table['rownames'].length == 2) && table['rownames'].length % 2 == 0 ? 'even': ''}\">\n" # Dispaly coloring correctly if there are only two rows and only the first is displayed
            out << "\t<tr class=\"coltotal #{table['rownames'].length % 2 == 0 ? 'even': ''}\">\n"
            out << "\t\t<th class=\"sidehead\">Total</th>\n"
            table['colnames'].each_with_index do |colname, i|
              coltotal = 0
              (1..(table['rownames'].length)).each_with_index do |jj, j|
                coltotal += table['values'][j][i]
              end
              colpercent = ((coltotal / total_n.to_f) * 10000).round/100.0
              out << "\t\t<td>#{colpercent}% (#{coltotal})</td>\n"
            end
            
            # Total for table
            out << "\t\t<td class=\"rowtotal\">#{total_n}</td>"
            out << "\t</tr>\n"
            out << "</table>\n"

            # Statistics
            if table['statistics']['type'] != ""
              p = (table['statistics']['result'].to_f*10000).round/10000.0
              out << "<p class=\"statistics\"><span style=\"#{"font-weight: bold; background-color: yellow;" if p <= 0.05}\">Pr(|T| > |t|) = #{p}</span> (#{table['statistics']['type']})</p>"
            end

          elsif table['type'] == 'sum'
            table['values'].map!{|v| (v == "." || v == "") ? "n/a" : (Float(v)*100).round/100.0}
            out << "<table>\n"
            out << "\t<tr class=\"tophead\"><th></th>#{table['colnames'].map{|n|"<th>"+n+"</th>"}.join}</tr>\n"


            out << "\t<tr class=\"even\">\n\t\t<th>N</th>\n"
            table['colnames'].each_with_index do |column, i|
              out << "\t\t<td>#{table['values'][i*6].to_i}</td>\n"
            end
            out << "\t</tr>\n"



            out << "\t<tr>\n\t\t<th>Mean (SD)</th>\n"
            table['colnames'].each_with_index do |column, i|
              out << "\t\t<td>#{table['values'][i*6+1]} (#{table['values'][i*6+2]})</td>\n"
            end
            out << "\t</tr>\n"
            
            out << "\t<tr class=\"even\">\n\t\t<th>Median</th>\n"
            table['colnames'].each_with_index do |column, i|
              out << "\t\t<td>#{table['values'][i*6+3]}</td>\n"
            end
            out << "\t</tr>\n"
            
            
            out << "\t<tr>\n\t\t<th>Range</th>\n"
            table['colnames'].each_with_index do |column, i|
              out << "\t\t<td>[#{table['values'][i*6+4]}, #{table['values'][i*6+5]}]</td>\n"
            end
            out << "\t</tr>\n"
            
            out << "</table>\n"
            # Statistics
            if table['statistics']['type'] != ""
              p = (table['statistics']['result'].to_f*10000).round/10000.0
              out << "<p class=\"statistics\"><span style=\"#{"font-weight: bold; background-color: yellow;" if p <= 0.05}\">Pr(|T| > |t|) = #{p}</span> (#{table['statistics']['type']})</p>"
            end
          elsif table['type'] == 'tab1'
            table['percents'] = Array.new
            sum = 0
            table['values'].each {|v| sum += v}
            table['values'].each_with_index do |v,i|
              table['percents'][i] = (v.to_f/sum*10000).round/100.0
            end
            out << "<table>\n"
              out << "\t<tr class=\"tophead\"><th></th><th>% (N)</th></tr>\n"
              table['rownames'].each_with_index do |row,i|
                out << "\t<tr class=\"#{i % 2 == 0 ? 'even': ''}\">\n\t\t<th class=\"sidehead\">#{table['rownames'][i]}</th>\n"
                out << "<td>#{table['percents'][i]} (#{table['values'][i]})</td>\n"
                out << "\t</tr>\n"
              end
            out << "</table>\n"
          elsif table['type'] == 'multi_tab'
            out << "<table>\n"
            out << "\t<tr class=\"tophead\"><th></th>#{table['colnames'].map{|c| "<th>#{c}</th>"}.join('')}<th>Total</th><th>P value</th></tr>\n"
            table['values'].each_with_index do |value, i|
              out << "\t<tr class=\"#{i % 2 == 0 ? 'even': ''}\">\n\t\t<th class=\"sidehead\">#{table['rownames'][i]}</th>\n"
              rowdata = value.values[0]
              pp rowdata
              case value.keys[0]
              when "binary"
                for j in (0...table['colnames'].length)
                  out << "\t\t<td>#{Integer.percentage(rowdata['count'][j], rowdata['total'][j])}% (#{rowdata['count'][j]}/#{rowdata['total'][j]})</td>\n"
                end
                count_total = rowdata['count'].inject(0){|total, v| total += v; total} 
                total_total = rowdata['total'].inject(0){|total, v| total += v; total}
                out << "\t\t<td class=\"rowtotal\">#{Integer.percentage(count_total,total_total)}% (#{count_total}/#{total_total})</td>\n"
                out << "\t\t<td>#{Float.p_round(rowdata['p'])}</td>\n"
              when "continuous"
                for j in (0...table['colnames'].length)
                  out << "\t\t<td>Mean: #{rowdata['mean'][j].to_f.round(2)}<br>(SD: #{rowdata['sd'][j].to_f.round(2)}; N: #{rowdata['n'][j]})</td>\n"
                end
                out << "\t\t<td class=\"rowtotal\">Mean: #{rowdata['mean'].last.to_f.round(2)}<br>(SD: #{rowdata['sd'].last.to_f.round(2)}; N: #{rowdata['n'].last})</td>\n"
                out << "\t\t<td>#{Float.p_round(rowdata['p'])}</td>\n"
              else
                raise "Invalid type"
              end
              out << "\t</tr>\n"
            end
            out << "</table>\n"
          end
          output[table['sortby']] = Hash.new
          # output[table['sortby']]['title'] = "#{table['title'][0]}"
          output[table['sortby']]['content'] = out
        end







        template_data = Psych.load template_file

        template = ""
        template_data['content'].each_with_index do |section, k|
          section['items'].each_with_index do |heading_group, i|
            heading_group['items'].each_with_index do |item, j|
              template << '<div class="block">'+"\n"
              if i == 0 && j == 0 && k == 0
                template << "\t <h1 id=\"title\">#{template_data['title']}\n"
                template << "\t\t<div class=\"subtitle\">#{template_data['subtitle']}</div>\n" unless template_data['subtitle'] == nil
                template << "\t</1>\n"
              end
              template << "\t<h2>#{section['section']}</h2>\n" if j == 0 && i == 0
              template << "\t<h3>#{heading_group['heading']}</h3>\n" if j == 0 && heading_group['heading'] != ""
              template << "\t<h4>#{item['name']}</h4>\n"
              template << "\t<p>#{item['description']}</p>\n" unless item['description'] == nil
              begin
                template << "\t#{output[item['content']]['content']}\n"
              rescue
                template << "\tCould not find #{item['content']}"
              end
              template << "\t<div class=\"spacer\">***</div>\n"
              template << '</div>'+"\n"
            end
          end
        end

        statistics_css = (template_data['statistics'] ? "": ".statistics{ display: none; }")

        out = <<-EOF
        <html>
        <head>
        <link rel="stylesheet" type="text/css" href="beautify.css" />
        <link href='http://fonts.googleapis.com/css?family=Droid+Serif:regular,bold' rel='stylesheet' type='text/css'>
        <link href='http://fonts.googleapis.com/css?family=Droid+Sans:regular,bold' rel='stylesheet' type='text/css'>


        <script src="jquery.min.js" type="text/javascript"></script>
        <script src="beautify.js" type='text/javascript'></script>
        <style>
          #{statistics_css }
        </style>
        </head>
        <body>
        <div id="pages"></div>
        <div id="wrapper">
        EOF

        out << template

        out << "</div></body></html>"

        output_file = File.join(options[:output], 'beautify.html')
        File.open(output_file, 'w') {|f| f.write(out) }

        ['beautify.css', 'beautify.js', 'jquery.min.js'].each do |file|
          if File.open(File.join(options[:output], file), 'w') do |f|
            f.write("/* v" << Beautify::Application.version << " */\n" << IO.read(File.join(File.dirname(__FILE__), '..', 'assets', file)))
          end
            puts "Asset #{file} written."
          else
            puts "Asset #{file} could not be written."
          end
        end

        puts "Wrote HTML to #{output_file}."
      end
    end
  end
end