class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    # 利用規約にチェックがあれば現在時刻を保存
    @user.terms_accepted_at = Time.current if params[:user][:terms_of_service] == "1"

    if @user.save
      start_new_session_for @user # Rails 8標準のセッション開始メソッド
      redirect_to root_path, notice: "アカウントを登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation)
  end
end