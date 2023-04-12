import clsx from "clsx"
import React, { useCallback, useEffect, useMemo, useState } from "react"
import { Controller, useFieldArray, useForm, useWatch } from "react-hook-form"
import { v4 as uuidv4 } from "uuid"
import Button from "../../../../components/fundamentals/button"
import PlusIcon from "../../../../components/fundamentals/icons/plus-icon"
import TrashIcon from "../../../../components/fundamentals/icons/trash-icon"
import IconTooltip from "../../../../components/molecules/icon-tooltip"
import InputField from "../../../../components/molecules/input"
import Modal from "../../../../components/molecules/modal"
import TagInput from "../../../../components/molecules/tag-input"
import { useDebounce } from "../../../../hooks/use-debounce"
import useToggleState from "../../../../hooks/use-toggle-state"
import { NestedForm } from "../../../../utils/nested-form"
import { CustomsFormType } from "../../components/customs-form"
import { DimensionsFormType } from "../../components/dimensions-form"
import CreateFlowVariantForm, {
  CreateFlowVariantFormType,
} from "../../components/variant-form/create-flow-variant-form"
import Metadata, {
  MetadataField,
} from "../../../../components/organisms/metadata"

export type AddMetadataFormType = {
  data: MetadataField[]
}

type Props = {
  form: NestedForm<AddMetadataFormType>
}

const AddMetadataForm = ({ form }: Props) => {
  const { control, path } = form
  const watchedMetadata = useWatch({
    control: control,
    name: path("data"),
  })
  const {
    append: appendMetadata,
    remove: removeMetadata,
    update: updateMetadata,
  } = useFieldArray({
    control,
    name: path("data"),
    shouldUnregister: true,
  })

  const setMetadata = (metadata: MetadataField[]) => {
    for (let i = 0; i < watchedMetadata.length; i++) {
      removeMetadata(i)
    }

    for (const meta of metadata) {
      appendMetadata(meta)
    }

    console.log(metadata)
  }

  return (
    <>
      <div>
        <div className="flex items-center gap-x-2xsmall">
          <h3 className="inter-base-semibold">Product metadata</h3>
          <IconTooltip
            type="info"
            content="Metadata are used to define specifications"
          />
        </div>
        <div className="mt-xlarge w-full">
          <Metadata setMetadata={setMetadata} metadata={watchedMetadata} />
        </div>
      </div>
    </>
  )
}

export default AddMetadataForm
