import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonicModule } from '@ionic/angular';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

import { HomePage } from './home.page';
import { PoSyncModule } from '@portinari/portinari-sync';
import { InterceptorModule } from '../../interceptors/interceptor.module';

@NgModule({
    imports: [
        CommonModule,
        InterceptorModule,
        FormsModule,
        IonicModule,
        PoSyncModule,
        RouterModule.forChild([{ path: '', component: HomePage }])
    ],
    declarations: [HomePage],
})
export class HomePageModule { }
