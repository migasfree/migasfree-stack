from migasfree_sdk.api import ApiToken


# SI insecure=True

# 1.- Deshabilitar warnings 
import urllib3
urllib3.disable_warnings()

# 2.- en requests añadir verify


def main():
    user = "reader"
    api = ApiToken(user=user)
    api.protocol="https" 
    cid = 1

    # METHOD 1
    data = api.get("computers", {"id": cid})
    print(data)

    # METHOD 2
    data = api.get("computers/" + str(cid), {})
    print(data)


if __name__ == "__main__":
    main()