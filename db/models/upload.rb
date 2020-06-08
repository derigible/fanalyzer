# frozen_string_literal: true

module Models
  class Upload < Sequel::Model
  end
end

Models::Upload.plugin :timestamps, create: :timestamp, update: :timestamp
