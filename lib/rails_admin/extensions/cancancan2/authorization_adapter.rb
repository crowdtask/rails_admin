module RailsAdmin
  module Extensions
    module CanCanCan2
      class AuthorizationAdapter < RailsAdmin::Extensions::CanCanCan::AuthorizationAdapter
        def authorize(action, abstract_model = nil, model_object = nil)
          return unless action
          subject = model_object || abstract_model && abstract_model.model
          if subject.nil?
            subject, action = action, :read
          end
          @controller.current_ability.authorize!(action, subject)
        end

        def authorized?(action, abstract_model = nil, model_object = nil)
          return unless action
          subject = model_object || abstract_model && abstract_model.model
          if subject.nil?
            subject, action = action, :read
          end
          @controller.current_ability.can?(action, subject)
        end
      end
    end
  end
end
