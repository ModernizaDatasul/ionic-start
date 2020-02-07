import { NgModule } from '@angular/core';
import { HTTP_INTERCEPTORS } from '@angular/common/http';
import { ErrorInterceptorService } from './error-interceptor.service';
import { MingleHttpInterceptor } from '@totvs/mingle';

@NgModule({
    providers: [
        {
            provide: HTTP_INTERCEPTORS,
            useClass: ErrorInterceptorService,
            multi: true,
        },
        {
            provide: HTTP_INTERCEPTORS,
            useClass: MingleHttpInterceptor,
            multi: true
        }
    ],
})
export class InterceptorsModule { }
