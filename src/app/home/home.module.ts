import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonicModule } from '@ionic/angular';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

import { HomePage } from './home.page';
import { PoSyncModule } from '@portinari/portinari-sync';
import { InterceptorsModule } from '../../interceptors/interceptors.module';

@NgModule({
    imports: [
        CommonModule,
        InterceptorsModule,
        FormsModule,
        IonicModule,
        PoSyncModule,
        RouterModule.forChild([{ path: '', component: HomePage }])
    ],
    declarations: [HomePage],
})
export class HomePageModule { }
