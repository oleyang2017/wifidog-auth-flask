import flask

from app.admin import VoucherAdmin
from app.models import User, Role, db, users
from app.resources import api, GatewayResource, NetworkResource, UserResource, VoucherResource, logos
from flask.ext.login import current_user, LoginManager
from flask.ext.misaka import Misaka
from flask.ext.uploads import configure_uploads
from flask.ext.potion.contrib.principals.needs import HybridRelationshipNeed
from flask.ext.principal import Identity, UserNeed, AnonymousIdentity, identity_loaded, RoleNeed, Principal
from flask.ext.security import Security


def create_app():
    app = flask.Flask(__name__)
    app.config.from_object('config')

    init_db(app)

    api.init_app(app)

    markdown = Misaka()

    security = Security()
    security.init_app(app, users)

    principals = Principal()
    principals.init_app(app)

    markdown.init_app(app)

    configure_uploads(app, logos)

    from app.views import menu, bp

    menu.init_app(app)
    app.register_blueprint(bp)

    if False:
        login_manager = LoginManager(app)

        @login_manager.request_loader
        def load_user_from_request(request):
            if request.authorization:
                email, password = request.authorization.username, request.authorization.password
                user = User.query.filter_by(email=unicode(email)).first()

                if user is not None:
                    if verify_password(password, user.password):
                        return user

    @identity_loaded.connect_via(app)
    def on_identity_loaded(sender, identity):
        if not isinstance(identity, AnonymousIdentity):
            identity.provides.add(UserNeed(identity.id))

            for role in current_user.roles:
                identity.provides.add(RoleNeed(role.name))

    @principals.identity_loader
    def read_identity_from_flask_login():
        if current_user.is_authenticated():
            return Identity(current_user.id)
        return AnonymousIdentity()

    return app

def init_db(app):
    db.init_app(app)
    with app.app_context():
        db.create_all()
