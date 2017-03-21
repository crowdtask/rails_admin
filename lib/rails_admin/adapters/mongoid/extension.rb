module RailsAdmin
  module Adapters
    module Mongoid
      module Extension
        extend ActiveSupport::Concern

        # Mongoid accepts_nested_attributes_for does not store options in accessible scope,
        # so we intercept the call and store it in instance variable which can be accessed from outside
        module RailsAdminAcceptsNested
          def accepts_nested_attributes_for(*args)
            options = args.extract_options!
            args.each do |arg|
              nested_attributes_options[arg.to_sym] = options.reverse_merge(allow_destroy: false, update_only: false)
            end
            args << options
            super(*args)
          end
        end

        included do
          class_attribute :nested_attributes_options
          self.nested_attributes_options = {}
          class << self
            def rails_admin(&block)
              RailsAdmin.config(self, &block)
            end
          end
          self.prepend(RailsAdminAcceptsNested)
        end

        def rails_admin_default_object_label_method
          new_record? ? "new #{self.class}" : "#{self.class} ##{id}"
        end

        def safe_send(value)
          if attributes.detect { |k, _v| k.to_s == value.to_s }
            read_attribute(value)
          else
            send(value)
          end
        end
      end
    end
  end
end
