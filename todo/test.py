import urllib3

from migasfree_sdk.api import ApiToken


def main():
    api = ApiToken(user='reader')
    api.protocol = 'https'
    cid = 1

    # METHOD 1
    data = api.get('computers', {'id': cid})
    print(data)

    # METHOD 2
    data = api.get(f'computers/{cid}', {})
    print(data)


if __name__ == '__main__':
    urllib3.disable_warnings()
    main()
