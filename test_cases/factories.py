import factory
import datetime
from factory.fuzzy import (
    FuzzyChoice,
    FuzzyNaiveDateTime,
    FuzzyInteger,
    FuzzyText,
)
from server.models import (
    db,
    Command,
    Credential,
    EntityMetadata,
    Host,
    License,
    Service,
    Vulnerability,
    Workspace,
)

# Make partials for start and end date. End date must be after start date
FuzzyStartTime = lambda: (
    FuzzyNaiveDateTime(
        datetime.datetime.now() - datetime.timedelta(days=40),
        datetime.datetime.now() - datetime.timedelta(days=20),
    )
)
FuzzyEndTime = lambda: (
    FuzzyNaiveDateTime(
        datetime.datetime.now() - datetime.timedelta(days=19),
        datetime.datetime.now()
    )
)



class FaradayFactory(factory.alchemy.SQLAlchemyModelFactory):

    # id = factory.Sequence(lambda n: n)
    pass


class WorkspaceFactory(FaradayFactory):

    name = FuzzyText()

    class Meta:
        model = Workspace
        sqlalchemy_session = db.session


class WorkspaceObjectFactory(FaradayFactory):
    workspace = factory.SubFactory(WorkspaceFactory)

    @classmethod
    def build_dict(cls, **kwargs):
        ret = factory.build(dict, FACTORY_CLASS=cls)
        del ret['workspace']  # It is passed in the URL, not in POST data
        return ret


class HostFactory(WorkspaceObjectFactory):
    ip = factory.Faker('ipv4')
    description = FuzzyText()
    os = FuzzyChoice(['Linux', 'Windows', 'OSX', 'Android', 'iOS'])

    class Meta:
        model = Host
        sqlalchemy_session = db.session


class EntityMetadataFactory(WorkspaceObjectFactory):
    couchdb_id = factory.Sequence(lambda n: '{0}.1.2'.format(n))

    class Meta:
        model = EntityMetadata
        sqlalchemy_session = db.session


class ServiceFactory(WorkspaceObjectFactory):
    name = FuzzyText()
    description = FuzzyText()
    port = FuzzyInteger(1, 65535)
    protocol = FuzzyChoice(['tcp', 'udp'])
    host = factory.SubFactory(HostFactory)
    status = FuzzyChoice(Service.STATUSES)

    class Meta:
        model = Service
        sqlalchemy_session = db.session


class VulnerabilityFactory(WorkspaceObjectFactory):

    name = FuzzyText()
    description = FuzzyText()
    host = factory.SubFactory(HostFactory)
    entity_metadata = factory.SubFactory(EntityMetadataFactory)
    service = factory.SubFactory(ServiceFactory)
    workspace = factory.SubFactory(WorkspaceFactory)
    vuln_type = FuzzyChoice(['Vulnerability', 'VulnerabilityWeb'])
    attachments = '[]'
    policyviolations = '[]'
    refs = '[]'

    class Meta:
        model = Vulnerability
        sqlalchemy_session = db.session


class CredentialFactory(WorkspaceObjectFactory):
    username = FuzzyText()
    password = FuzzyText()

    class Meta:
        model = Credential
        sqlalchemy_session = db.session


class CommandFactory(WorkspaceObjectFactory):
    command = FuzzyText()

    class Meta:
        model = Command
        sqlalchemy_session = db.session


class LicenseFactory(FaradayFactory):
    product = FuzzyText()
    start_date = FuzzyStartTime()
    end_date = FuzzyEndTime()
    type = FuzzyText()

    class Meta:
        model = License
        sqlalchemy_session = db.session
