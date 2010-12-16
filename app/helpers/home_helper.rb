# encoding: utf-8
module HomeHelper
  def line_option line
    attrs = { :value => line.id }
    if line.fgcolor and line.bgcolor
      attrs[:style] = "color: ##{line.fgcolor}; background-color: ##{line.bgcolor}"
    end
    content_tag :option, line.full_name, attrs
  end
  def line_options_for_select lines
    lines_grouped = [ lines.select(&:is_urban?).collect {|l| line_option(l) }.join.html_safe,
                      lines.select(&:is_suburban?).collect {|l| line_option(l) }.join.html_safe,
                      lines.select(&:is_express?).collect {|l| line_option(l) }.join.html_safe,
                      lines.select(&:is_special?).collect {|l| line_option(l) }.join.html_safe ]
    titles_groups = [ "Lignes urbaines", "Lignes suburbaines",
                      "Lignes express", "Lignes spéciales" ]
    titles_groups.to_enum(:each_with_index).collect do |title,idx|
      content_tag :optgroup, lines_grouped[idx], { :label => title }
    end.join.html_safe
  end
end
