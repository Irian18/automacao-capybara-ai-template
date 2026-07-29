require_relative 'design_system'

module SelfHealing
  class Snapshot
    MAX_ELEMENTS = 100
    TEXT_EXCERPT_LIMIT = 1500

    def initialize(session, design_system: nil)
      @session = session
      @design_system = design_system || DesignSystem.load
    end

    def build
      doc = Nokogiri::HTML(@session.html)
      doc.css(@design_system.ignore_tags_selector).remove

      elements = doc.css(@design_system.interactive_selector_string)
                    .each_with_index
                    .filter_map { |el, i| describe(el, i) }
                    .first(MAX_ELEMENTS)

      {
        url: @session.current_url,
        title: doc.title,
        headings: headings(doc),
        interactive_elements: elements,
        visible_text_excerpt: visible_text_excerpt(doc)
      }.to_json
    end

    private

    def describe(el, idx)
      tag = el.name

      id = el['id']
      return nil if id && unstable_id?(id)

      test_id     = el['data-test-id'] || el['data-testid']
      formcontrol = el['formcontrolname']
      name        = el['name']
      routerlink  = el['routerlink']

      stable_selector = derive_selector(tag, el, test_id, id, formcontrol, routerlink, name)

      entry = {
        idx: idx,
        tag: tag,
        text: clean_text(el.text),
        id: id,
        name: name,
        type: el['type'],
        placeholder: el['placeholder'],
        value: extract_value(el),
        'aria-label' => el['aria-label'],
        'data-testid' => el['data-testid'],
        'data-test-id' => el['data-test-id'],
        href: el['href']&.[](0, 100),
        formcontrolname: formcontrol,
        routerlink: routerlink,
        stable_selector: stable_selector
      }.compact.reject { |_, v| v.to_s.empty? }

      kind = component_kind(tag, el)
      entry[:kind] = kind if kind

      entry
    end

    def headings(doc)
      doc.css('h1, h2, h3')
         .map(&:text)
         .map(&:strip)
         .reject(&:empty?)
         .first(10)
    end

    def visible_text_excerpt(doc)
      doc.css('body')
         .text
         .gsub(/\s+/, ' ')
         .strip
         .then { |text| text.length > TEXT_EXCERPT_LIMIT ? "#{text[0, TEXT_EXCERPT_LIMIT]}..." : text }
    end

    def clean_text(text)
      text.to_s.gsub(/\s+/, ' ').strip[0, 80]
    end

    def extract_value(el)
      case el.name
      when 'input'
        el['value'] || (el['type'] == 'checkbox' || el['type'] == 'radio' ? el['checked'] : nil)
      when 'textarea'
        el.text.strip[0, 200] if el.text && !el.text.strip.empty?
      when 'select'
        selected = el.css('option[selected]').first
        selected ? selected['value'] || selected.text.strip : nil
      end
    end

    def derive_selector(_tag, el, test_id, id, formcontrol, routerlink, name)
      return "[data-test-id=\"#{test_id}\"]" if test_id && !test_id.empty?
      return "##{id}" if id && !unstable_id?(id)
      return "[formcontrolname=\"#{formcontrol}\"]" if formcontrol
      return "a[routerlink=\"#{routerlink}\"]" if routerlink
      return "[name=\"#{name}\"]" if name && !name.empty?

      nil
    end

    def component_kind(tag, el)
      config = @design_system&.field_components&.[](tag)
      return config['kind'] if config && config['kind']

      case tag
      when 'input' then 'input'
      when 'select' then 'select'
      when 'textarea' then 'textarea'
      when 'button' then 'button'
      when 'a' then 'link'
      end
    end

    def unstable_id?(id)
      return true if id.nil? || id.strip.empty?
      @design_system.unstable_id_patterns.any? { |pat| id =~ pat }
    end
  end
end
