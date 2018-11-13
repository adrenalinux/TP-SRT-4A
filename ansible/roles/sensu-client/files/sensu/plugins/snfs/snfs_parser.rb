#! /usr/bin/env ruby

class SnfsParser
  def parse_raw_csv(raw_csv)
    tables_raw = raw_csv.split("\n\n")
    data = {
      common_data: parse_common_data_raw_csv(tables_raw[0]),
      data: []
    }
    tables_raw.delete_at(0)
    tables_raw.each do |table_raw|
      data[:data].push(parse_table_raw_csv(table_raw))
    end
    data
  end

  def parse_common_data_raw_csv(table_info)
    lines = table_info.lines.to_a
    lines.delete_if { |line| !line.match(/^#/) }
    lines.collect! { |line| line.chomp }
    common_data = {
      qustat_version: lines[0].split(',')[1].to_s.downcase,
      host: lines[1].split(',')[1].to_s.downcase,
      module: lines[2].split(',')[1].to_s.downcase,
      group: lines[3].split(',')[1].to_s.downcase,
      recorded: lines[4].split(',')[2].to_i
    }
    common_data
  end

  def parse_table_raw_csv(table)
    lines = table.lines.to_a
    lines.collect! { |line| line.chomp }
    table_infos = {
      table_number:  lines[0].split(',')[2].to_i,
      table_name: lines[0].split(',')[3].to_s,
      table_type: lines[0].split(',')[3].split('.')[0].to_s.downcase,
      table_attribute_1: lines[0].split(',')[3].split('.')[1].to_s.downcase,
      table_attribute_2: lines[0].split(',')[3].split('.')[2].to_s.downcase,
      table_data_type: lines[0].split(',')[3].split('.')[-1].to_s.downcase,
      table_time_last_reset: lines[1].split(',')[4].to_i,
      table_data: parse_table_data_raw_csv(lines).to_a,
    }
    table_infos
  end

  def parse_table_data_raw_csv(table)
    table.delete_if { |line| line.match(/^#/) }
    table_data = []
    table.each do |line|
      table_data.push({
        data_name: line.split(',')[0].gsub(' ', '_').to_s.downcase,
        data_type: line.split(',')[1].to_s.downcase,
        data_count: line.split(',')[2].to_i,
        data_min: line.split(',')[3].to_i,
        data_max: line.split(',')[4].to_i,
        data_tot_lvl: line.split(',')[5].to_i,
        data_avg: line.split(',')[6].to_i
      })
    end
    table_data
  end
end
