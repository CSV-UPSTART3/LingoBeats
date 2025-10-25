# frozen_string_literal: true

CODE_DIRS = %w[config app/models app/infrastructure app/views app/controllers].freeze

# Requires all ruby files in specified app folders
def require_app
  CODE_DIRS.each do |dir|
    Dir.glob("./#{dir}/**/*.rb").each { |file| require file }
  end
end
