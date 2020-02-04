import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonicModule } from '@ionic/angular';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

import { LoginPage } from './login.page';
import { PoModule } from '@portinari/portinari-ui';

import { PoPageLoginModule } from '@portinari/portinari-templates';
import { PoModalPasswordRecoveryModule } from '@portinari/portinari-templates';


@NgModule({
    imports: [
        CommonModule,
        FormsModule,
        IonicModule,
        PoModule,
        PoPageLoginModule,
        PoModalPasswordRecoveryModule,
        RouterModule.forChild([
            {
                path: '',
                component: LoginPage
            }
        ])
    ],
    entryComponents: [
    ],
    declarations: [
        LoginPage
    ]
})
export class LoginPageModule { }
