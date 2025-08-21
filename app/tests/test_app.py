import app as hello

def test_root_returns_hello():
    client = hello.app.test_client()
    resp = client.get("/")
    assert resp.status_code == 200
    assert "Hello, world!" in resp.data.decode()
