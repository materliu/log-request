<h1 align="center">Log Request</h1>

## About Log Request

Log Request is a web application tools based Laravel. 

Log Request is accessible, powerful, and provides one-key deploy required for logging anything you want in your request!

## Deploy Log Request
```bash
git clone git@github.com:materliu/log-request.git
cd log-request
docker build -t log/app .
docker run -it --rm -p 80:80 log/app
```

then visit: http://localhost

![homepage](https://raw.githubusercontent.com/materliu/log-request/master/home-page.png)

as the homepage said:

1. Just post to /api/log with data any format you like!

![log-post](https://raw.githubusercontent.com/materliu/log-request/master/log-post.png)

2. Then view your data by navigating to /log-viewer!

![log-viewer](https://raw.githubusercontent.com/materliu/log-request/master/log-viewer.png)

### Want Run Directly
```bash
docker run -it --rm -p 80:80 ghcr.io/materliu/log-request:main
```

If you test in Apple Silicon
```bash
docker run -it --rm -p 80:80 --platform linux/x86_64 ghcr.io/materliu/log-request:main
```

## Log Request Sponsors

We would like to extend our thanks to the following sponsors for funding Laravel development. If you are interested in becoming a sponsor, please visit the Laravel [Patreon page](https://patreon.com/taylorotwell).

## Contributing

Thank you for considering contributing to the Log Request! The contribution guide can be found in the [Laravel documentation](https://laravel.com/docs/contributions).

## Code of Conduct

In order to ensure that the Laravel community is welcoming to all, please review and abide by the [Code of Conduct](https://laravel.com/docs/contributions#code-of-conduct).

## Security Vulnerabilities

If you discover a security vulnerability within Laravel, please send an e-mail to Taylor Otwell via [taylor@laravel.com](mailto:taylor@laravel.com). All security vulnerabilities will be promptly addressed.

## License

The Log Request is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
