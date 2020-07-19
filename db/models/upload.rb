# frozen_string_literal: true

class Upload < Sequel::Model
end

Models::Upload.plugin :timestamps, create: :timestamp, update: :timestamp
