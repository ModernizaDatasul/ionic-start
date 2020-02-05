import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ErrorInterceptorService implements HttpInterceptor {
    intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
        let req: HttpRequest<any>;

        const headers = new HttpHeaders({
            'X-Portinari-No-Error': 'true'
        });

        req = request.clone({headers});

        return next.handle(req);
    }
}
