class Admin::ProfileController < Admin::BaseController
  def show
    render json: {
      admin: current_admin.as_json(only: [:id, :email, :first_name, :last_name, :role])
    }
  end
end
